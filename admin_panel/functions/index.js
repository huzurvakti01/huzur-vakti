import admin from 'firebase-admin';
import fetch from 'node-fetch';
import { HttpsError, onCall, onRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated as onFirestoreDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule as onScheduler } from 'firebase-functions/v2/scheduler';

admin.initializeApp();

const REGION = 'europe-west1';
const OPENAI_MODEL = process.env.OPENAI_MODEL || 'gpt-4o-mini';

function adminEmails() {
  const configured = process.env.ADMIN_EMAILS || process.env.FUNCTIONS_CONFIG_ADMIN_EMAILS || '';
  return `${configured},bilal.dag403@gmail.com`
    .split(',')
    .map((item) => item.trim().toLowerCase())
    .filter(Boolean);
}

function openAiKey() {
  const key = process.env.OPENAI_API_KEY || process.env.FUNCTIONS_CONFIG_OPENAI_KEY || '';
  if (!key) {
    throw new HttpsError('failed-precondition', 'OPENAI_API_KEY is not configured on the server.');
  }
  return key;
}

async function assertAdmin(request) {
  const email = request.auth?.token?.email?.toLowerCase();
  if (!request.auth || !email) {
    throw new HttpsError('unauthenticated', 'Admin authentication required.');
  }

  if (!adminEmails().includes(email)) {
    throw new HttpsError('permission-denied', 'God Mode admin permission required.');
  }

  return email;
}

async function openAiJson({ system, user, temperature = 0.2 }) {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${openAiKey()}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      temperature,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user }
      ]
    })
  });

  if (!response.ok) {
    const body = await response.text();
    throw new HttpsError('internal', `OpenAI request failed: ${response.status} ${body.slice(0, 240)}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content || '{}';

  try {
    return JSON.parse(content);
  } catch (error) {
    throw new HttpsError('internal', 'OpenAI returned invalid JSON.');
  }
}

async function logAiAction(payload) {
  await admin.firestore().collection('ai_action_logs').add({
    ...payload,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
}

export const assertGodModeAdmin = onCall({ region: REGION }, async (request) => {
  const email = await assertAdmin(request);
  return { ok: true, email };
});

export const listAuthUsers = onCall({ region: REGION }, async (request) => {
  await assertAdmin(request);

  const limit = Math.min(Number(request.data?.limit || 100), 1000);
  const pageToken = request.data?.pageToken || undefined;
  const result = await admin.auth().listUsers(limit, pageToken);

  return {
    users: result.users.map((user) => ({
      uid: user.uid,
      email: user.email || '',
      displayName: user.displayName || '',
      disabled: user.disabled,
      createdAt: user.metadata.creationTime,
      lastSeenAt: user.metadata.lastSignInTime
    })),
    pageToken: result.pageToken || null
  };
});

export const updateUserGodMode = onCall({ region: REGION }, async (request) => {
  const adminEmail = await assertAdmin(request);
  const data = request.data || {};
  const uid = String(data.uid || '');

  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }

  const dhikrToday = Number(data.dhikrToday || 0);
  const streakDays = Number(data.streakDays || 0);
  const qazaCounts = data.qazaCounts || {};
  const premiumExpiresAt = data.premiumExpiresAt ? String(data.premiumExpiresAt) : null;

  if (!Number.isFinite(dhikrToday) || !Number.isFinite(streakDays)) {
    throw new HttpsError('invalid-argument', 'Invalid numeric values.');
  }

  const progress = {
    dhikrToday,
    streakDays,
    qazaCounts,
    updatedAt: new Date().toISOString()
  };

  const db = admin.firestore();
  const userRef = db.collection('users').doc(uid);

  await userRef.set({
    isPremium: Boolean(data.isPremium),
    isVip: Boolean(data.isVip),
    premiumPlan: Boolean(data.isVip) ? 'lifetime' : data.isPremium ? 'manual' : null,
    premiumSource: Boolean(data.isVip) ? 'godmode_vip' : data.isPremium ? 'godmode_manual' : null,
    premiumExpiresAt,
    deviceBanned: Boolean(data.deviceBanned),
    bannedDeviceIds: data.bannedDeviceIds || [],
    dhikrToday,
    streakDays,
    qazaCounts,
    progress,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: adminEmail
  }, { merge: true });

  await userRef.collection('cloud_sync').doc('ibadah_progress').set({
    ...progress,
    schemaVersion: 2,
    cloudUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    editedByGodMode: true,
    editedBy: adminEmail
  }, { merge: true });

  await db.collection('admin_audit_logs').add({
    type: 'user_godmode_updated',
    targetUid: uid,
    adminEmail,
    payload: {
      isPremium: Boolean(data.isPremium),
      isVip: Boolean(data.isVip),
      premiumExpiresAt,
      deviceBanned: Boolean(data.deviceBanned),
      dhikrToday,
      streakDays,
      qazaCounts
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { ok: true };
});

export const hardDeleteUser = onCall({ region: REGION }, async (request) => {
  const adminEmail = await assertAdmin(request);
  const uid = String(request.data?.uid || '');

  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }

  const db = admin.firestore();

  async function deleteCollection(path, batchSize = 200) {
    const ref = db.collection(path);

    while (true) {
      const snapshot = await ref.limit(batchSize).get();
      if (snapshot.empty) break;

      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();

      if (snapshot.size < batchSize) break;
    }
  }

  await deleteCollection(`users/${uid}/cloud_sync`);
  await deleteCollection(`users/${uid}/premium_sync`);
  await db.collection('users').doc(uid).delete().catch(() => null);
  await admin.auth().deleteUser(uid).catch((error) => {
    if (error.code !== 'auth/user-not-found') throw error;
  });

  await db.collection('admin_audit_logs').add({
    type: 'user_hard_deleted',
    targetUid: uid,
    adminEmail,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { ok: true };
});

export const resetUserPassword = onCall({ region: REGION }, async (request) => {
  const adminEmail = await assertAdmin(request);
  const email = String(request.data?.email || '').trim();

  if (!email) {
    throw new HttpsError('invalid-argument', 'email is required.');
  }

  const link = await admin.auth().generatePasswordResetLink(email);

  await admin.firestore().collection('admin_audit_logs').add({
    type: 'password_reset_link_generated',
    targetEmail: email,
    adminEmail,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { ok: true, link };
});

export const banUserDevice = onCall({ region: REGION }, async (request) => {
  const adminEmail = await assertAdmin(request);
  const uid = String(request.data?.uid || '');
  const deviceId = String(request.data?.deviceId || '').trim();

  if (!uid || !deviceId) {
    throw new HttpsError('invalid-argument', 'uid and deviceId are required.');
  }

  await admin.firestore().collection('users').doc(uid).set({
    deviceBanned: true,
    bannedDeviceIds: admin.firestore.FieldValue.arrayUnion(deviceId),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: adminEmail
  }, { merge: true });

  await admin.firestore().collection('device_bans').doc(deviceId).set({
    uid,
    deviceId,
    banned: true,
    bannedBy: adminEmail,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });

  await admin.firestore().collection('admin_audit_logs').add({
    type: 'device_banned',
    targetUid: uid,
    deviceId,
    adminEmail,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { ok: true };
});

export const publishKillSwitchConfig = onCall({ region: REGION }, async (request) => {
  const adminEmail = await assertAdmin(request);
  const data = request.data || {};
  const minVersionCode = Number(data.minVersionCode || 1);

  if (!Number.isInteger(minVersionCode) || minVersionCode < 1) {
    throw new HttpsError('invalid-argument', 'minVersionCode must be positive integer.');
  }

  const payload = {
    forceUpdateEnabled: Boolean(data.forceUpdateEnabled),
    minVersionCode,
    aiChatEnabled: Boolean(data.aiChatEnabled),
    zikirmatikEnabled: Boolean(data.zikirmatikEnabled),
    duaCommunityEnabled: Boolean(data.duaCommunityEnabled),
    premiumLibraryEnabled: Boolean(data.premiumLibraryEnabled),
    cloudSyncEnabled: Boolean(data.cloudSyncEnabled),
    updatedAt: new Date().toISOString(),
    updatedBy: adminEmail
  };

  await admin.firestore().collection('admin_settings').doc('kill_switch').set(payload, { merge: true });

  const remoteConfig = admin.remoteConfig();
  const template = await remoteConfig.getTemplate();

  const params = {
    force_update_enabled: String(payload.forceUpdateEnabled),
    min_version_code: String(payload.minVersionCode),
    ai_chat_enabled: String(payload.aiChatEnabled),
    zikirmatik_enabled: String(payload.zikirmatikEnabled),
    dua_community_enabled: String(payload.duaCommunityEnabled),
    premium_library_enabled: String(payload.premiumLibraryEnabled),
    cloud_sync_enabled: String(payload.cloudSyncEnabled),
    godmode_config_json: JSON.stringify(payload)
  };

  for (const [key, value] of Object.entries(params)) {
    template.parameters[key] = {
      defaultValue: { value },
      description: `God Mode controlled parameter: ${key}`
    };
  }

  await remoteConfig.publishTemplate(template);

  await admin.firestore().collection('admin_audit_logs').add({
    type: 'kill_switch_published',
    adminEmail,
    payload,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { ok: true, payload };
});

export const analyzeDuaText = onCall({ region: REGION, timeoutSeconds: 60 }, async (request) => {
  const adminEmail = await assertAdmin(request);
  const duaId = String(request.data?.duaId || '');
  const text = String(request.data?.text || '').trim();

  if (!text) {
    throw new HttpsError('invalid-argument', 'text is required.');
  }

  const analysis = await openAiJson({
    system: 'You are a moderation classifier. Return only JSON with toxicity_score 0..1, sentiment, categories array, reason.',
    user: `Analyze this Turkish user-generated prayer/community text for toxicity, harassment, hate, self-harm, sexual content, spam, threats, and religiously sensitive abuse. Text: ${text}`
  });

  const toxicity = Number(analysis.toxicity_score || 0);
  const harmful = toxicity > 0.8;

  if (harmful && duaId) {
    await admin.firestore().collection('dua_requests').doc(duaId).delete();
  }

  await logAiAction({
    type: harmful ? 'dua_auto_deleted' : 'dua_analyzed',
    duaId: duaId || null,
    adminEmail,
    toxicityScore: toxicity,
    result: analysis,
    source: 'manual_admin_ai_analysis'
  });

  return { ok: true, harmful, analysis };
});

export const aiModerateDuaOnCreate = onFirestoreDocumentCreated(
  { region: REGION, document: 'dua_requests/{duaId}', timeoutSeconds: 60 },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data() || {};
    const text = String(data.text || '').trim();

    if (!text) return;

    const analysis = await openAiJson({
      system: 'You are a moderation classifier. Return only JSON with toxicity_score 0..1, sentiment, categories array, reason.',
      user: `Analyze this Turkish user-generated prayer/community text for toxicity, harassment, hate, self-harm, sexual content, spam, threats, and religiously sensitive abuse. Text: ${text}`
    });

    const toxicity = Number(analysis.toxicity_score || 0);
    const harmful = toxicity > 0.8;

    if (harmful) {
      await snapshot.ref.delete();
    } else {
      await snapshot.ref.set({
        aiModerated: true,
        aiToxicityScore: toxicity,
        aiSentiment: analysis.sentiment || null,
        aiModeratedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    }

    await logAiAction({
      type: harmful ? 'dua_auto_deleted' : 'dua_auto_approved',
      duaId: event.params.duaId,
      uid: data.uid || data.userId || null,
      toxicityScore: toxicity,
      result: analysis,
      source: 'firestore_trigger'
    });
  }
);

export const generateDailyIslamicContent = onCall(
  { region: REGION, timeoutSeconds: 90 },
  async (request) => {
    const adminEmail = await assertAdmin(request);
    const theme = String(request.data?.theme || 'huzur, ibadet bilinci, şükür').trim();

    const result = await openAiJson({
      temperature: 0.5,
      system: 'You generate respectful Islamic app content in Turkish. Return JSON only with ayah, hadith, dua. Each has title, body, source_note. Avoid unsupported exact source claims unless source_note says verify before publication.',
      user: `Generate daily Islamic content for a Turkish prayer app. Theme: ${theme}. Keep it concise, warm, and suitable for app users.`
    });

    const today = new Date().toISOString().slice(0, 10);
    const doc = {
      date: today,
      theme,
      ayah: result.ayah || {},
      hadith: result.hadith || {},
      dua: result.dua || {},
      generatedBy: adminEmail,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'generated'
    };

    await admin.firestore().collection('daily_content').doc(today).set(doc, { merge: true });

    await logAiAction({
      type: 'daily_content_generated',
      adminEmail,
      targetDoc: `daily_content/${today}`,
      result
    });

    return { ok: true, date: today, content: result };
  }
);

export const scheduledDailyIslamicContent = onScheduler(
  { region: REGION, schedule: '0 4 * * *', timeZone: 'Europe/Istanbul', timeoutSeconds: 90 },
  async () => {
    const result = await openAiJson({
      temperature: 0.5,
      system: 'You generate respectful Islamic app content in Turkish. Return JSON only with ayah, hadith, dua. Each has title, body, source_note. Avoid unsupported exact source claims unless source_note says verify before publication.',
      user: 'Generate daily Islamic content for a Turkish prayer app. Theme: sabah huzuru, dua, şükür.'
    });

    const today = new Date().toISOString().slice(0, 10);

    await admin.firestore().collection('daily_content').doc(today).set({
      date: today,
      theme: 'scheduled',
      ayah: result.ayah || {},
      hadith: result.hadith || {},
      dua: result.dua || {},
      generatedBy: 'scheduled_ai',
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'generated'
    }, { merge: true });

    await logAiAction({
      type: 'daily_content_scheduled',
      targetDoc: `daily_content/${today}`,
      result
    });
  }
);

export const generateDashboardAiSummary = onCall(
  { region: REGION, timeoutSeconds: 60 },
  async (request) => {
    const adminEmail = await assertAdmin(request);
    const db = admin.firestore();

    const [users, aiLogs, duas, content] = await Promise.all([
      db.collection('users').limit(500).get(),
      db.collection('ai_action_logs').orderBy('createdAt', 'desc').limit(50).get(),
      db.collection('dua_requests').orderBy('createdAt', 'desc').limit(100).get(),
      db.collection('daily_content').orderBy('generatedAt', 'desc').limit(7).get()
    ]);

    const metrics = {
      users: users.size,
      premiumUsers: users.docs.filter((doc) => Boolean(doc.data().isPremium || doc.data().isVip)).length,
      recentAiActions: aiLogs.size,
      recentDuas: duas.size,
      recentDailyContentDocs: content.size
    };

    const summary = await openAiJson({
      temperature: 0.3,
      system: 'You are an app analytics assistant. Return JSON only with summary, risks array, opportunities array, recommended_actions array.',
      user: `Interpret these admin metrics for a Turkish Islamic lifestyle app and provide actionable suggestions: ${JSON.stringify(metrics)}`
    });

    await logAiAction({
      type: 'dashboard_ai_summary_generated',
      adminEmail,
      metrics,
      result: summary
    });

    return { ok: true, metrics, summary };
  }
);

// Hardened mobile OpenAI proxy with Firebase Auth, per-user rate limiting and audit logs.
function mobileClientIp(req) {
  const forwarded = req.get('x-forwarded-for');
  if (forwarded) return forwarded.split(',')[0].trim();
  return req.ip || 'unknown';
}

async function verifyMobileBearer(req) {
  const header = req.get('Authorization') || '';
  const match = header.match(/^Bearer\s+(.+)$/i);

  if (!match) {
    throw new HttpsError('unauthenticated', 'Missing Firebase ID token.');
  }

  return admin.auth().verifyIdToken(match[1], true);
}

function sanitizeText(value, max = 4000) {
  return String(value || '')
    .replace(/\u0000/g, '')
    .trim()
    .slice(0, max);
}

async function enforceAiRateLimit(uid) {
  const bucketId = `${uid}_${Math.floor(Date.now() / 60000)}`;
  const ref = admin.firestore().collection('ai_rate_limits').doc(bucketId);

  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = snap.exists ? snap.data().count || 0 : 0;

    if (current >= 5) {
      throw new HttpsError('resource-exhausted', 'Dakikada en fazla 5 AI isteği gönderebilirsiniz.');
    }

    tx.set(ref, {
      uid,
      count: current + 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 10 * 60 * 1000)
    }, { merge: true });
  });
}

function responseLanguageName(code) {
  switch (code) {
    case 'tr':
      return 'Turkish';
    case 'ar':
      return 'Arabic';
    case 'fr':
      return 'French';
    case 'ur':
      return 'Urdu';
    case 'id':
      return 'Indonesian';
    default:
      return 'English';
  }
}

async function writeAiAuditLog({ uid, languageCode, isPremium, status, ip, promptLength, answerLength = 0, errorCode = null }) {
  await admin.firestore().collection('ai_audit_logs').add({
    uid,
    languageCode,
    isPremium: Boolean(isPremium),
    status,
    ip,
    promptLength,
    answerLength,
    errorCode,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
}

export const openAiChatProxy = onRequest({
  region: REGION,
  timeoutSeconds: 60,
  memory: '512MiB',
  secrets: ['OPENAI_API_KEY']
}, async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type, X-Huzur-Client');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ code: 'method_not_allowed', message: 'Only POST is allowed.' });
    return;
  }

  let uid = 'unknown';
  let languageCode = 'en';
  let isPremium = false;
  let prompt = '';

  try {
    const decoded = await verifyMobileBearer(req);
    uid = decoded.uid;

    await enforceAiRateLimit(uid);

    const body = typeof req.body === 'object' && req.body !== null ? req.body : {};
    prompt = sanitizeText(body.message || body.question);
    languageCode = sanitizeText(body.languageCode || 'en', 5);
    isPremium = Boolean(body.isPremium);

    if (prompt.length < 2) {
      throw new HttpsError('invalid-argument', 'Message is too short.');
    }

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${openAiKey()}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        temperature: 0.3,
        max_tokens: isPremium ? 900 : 450,
        messages: [
          {
            role: 'system',
            content:
              `You are Huzur Vakti Islamic assistant. Answer in ${responseLanguageName(languageCode)}. ` +
              'Be respectful and careful. Do not present answers as definitive fatwas. ' +
              'For sensitive religious matters, recommend consulting a qualified scholar.'
          },
          { role: 'user', content: prompt }
        ]
      })
    });

    const decodedBody = await response.json();

    if (!response.ok) {
      throw new HttpsError('internal', decodedBody?.error?.message || 'OpenAI request failed.');
    }

    const answer = decodedBody?.choices?.[0]?.message?.content?.trim() || '';

    await writeAiAuditLog({
      uid,
      languageCode,
      isPremium,
      status: 'success',
      ip: mobileClientIp(req),
      promptLength: prompt.length,
      answerLength: answer.length
    });

    res.status(200).json({
      answer,
      model: 'gpt-4o',
      disclaimer: 'AI cevabı kesin fetva değildir.'
    });
  } catch (error) {
    const code = error?.code || 'internal';
    const status =
      code === 'resource-exhausted' ? 429 :
      code === 'unauthenticated' ? 401 :
      code === 'invalid-argument' ? 400 : 500;

    try {
      await writeAiAuditLog({
        uid,
        languageCode,
        isPremium,
        status: 'error',
        ip: mobileClientIp(req),
        promptLength: prompt.length,
        errorCode: code
      });
    } catch (_) {}

    res.status(status).json({
      code,
      message: error?.message || 'AI proxy failed.'
    });
  }
});


export const setAdminClaim = onCall({
  region: REGION
}, async (request) => {
  if (!request.auth || request.auth.token.isAdmin !== true) {
    throw new HttpsError('permission-denied', 'Admin custom claim required.');
  }

  const uid = String(request.data?.uid || '');
  const isAdmin = Boolean(request.data?.isAdmin);

  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }

  await admin.auth().setCustomUserClaims(uid, { isAdmin });

  await admin.firestore().collection('admin_audit_logs').add({
    type: 'set_admin_claim',
    targetUid: uid,
    isAdmin,
    actorUid: request.auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { ok: true };
});
export const publishRemoteConfigValues = onCall({
  region: REGION
}, async (request) => {
  const adminEmail = await assertAdmin(request);
  const values = request.data?.values || {};

  if (!values || typeof values !== 'object' || Array.isArray(values)) {
    throw new HttpsError('invalid-argument', 'values must be an object.');
  }

  const allowedKeys = new Set([
    'isAiEnabled',
    'isWomenCalendarVisible',
    'isSeferiModeActive',
    'isMediaCenterActive',
    'areAdsEnabled',
    'isNativeAdEnabled',
    'isInterstitialEnabled',
    'isPremiumPaywallEnabled',
    'isCommunityEnabled',
    'isKidsModeEnabled',
    'admobNativeAndroidId',
    'admobNativeIosId',
    'admobInterstitialAndroidId',
    'admobInterstitialIosId',
    'premiumMonthlyLabel',
    'premiumYearlyLabel',
    'premiumLifetimeLabel',
    'premiumDiscountLabel'
  ]);

  const remoteConfig = admin.remoteConfig();
  const template = await remoteConfig.getTemplate();
  const sanitized = {};

  for (const [key, rawValue] of Object.entries(values)) {
    if (!allowedKeys.has(key)) continue;

    let value;
    if (typeof rawValue === 'boolean') {
      value = String(rawValue);
    } else if (typeof rawValue === 'number') {
      value = String(rawValue);
    } else {
      value = String(rawValue || '').slice(0, 1000);
    }

    sanitized[key] = value;
    template.parameters[key] = {
      defaultValue: { value },
      description: `App Engine & Brand Controller parameter: ${key}`
    };
  }

  if (Object.keys(sanitized).length === 0) {
    throw new HttpsError('invalid-argument', 'No allowed Remote Config keys supplied.');
  }

  await remoteConfig.publishTemplate(template);

  await admin.firestore().collection('admin_audit_logs').add({
    type: 'app_engine_remote_config_published',
    adminEmail,
    payload: sanitized,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { ok: true, publishedKeys: Object.keys(sanitized) };
});

function remoteConfigValue(value) {
  if (typeof value === 'boolean') return String(value);
  if (typeof value === 'number') return String(value);
  if (Array.isArray(value) || (value && typeof value === 'object')) return JSON.stringify(value);
  return String(value ?? '');
}

async function publishGodModeRemoteConfig(params, source) {
  const template = await admin.remoteConfig().getTemplate();

  for (const [key, value] of Object.entries(params)) {
    template.parameters[key] = {
      defaultValue: { value: remoteConfigValue(value) },
      description: `Synced from ${source}`
    };
  }

  await admin.remoteConfig().publishTemplate(template);
}

function themeToRemoteConfig(data) {
  return {
    godmode_logo_url: data.logoUrl || '',
    godmode_splash_image_url: data.splashImageUrl || '',
    godmode_primary_color: data.primaryColor || data.colors?.primary || '#0E7C66',
    godmode_colors_json: data.colors || {},
    godmode_font_style_json: data.fontStyle || {},
    godmode_localization_override_json: data.localization_override || {},
    godmode_theme_revision: data.revision || 1
  };
}

function featuresToRemoteConfig(data) {
  return {
    isAiEnabled: Boolean(data.ai_active),
    isWomenCalendarVisible: Boolean(data.women_calendar_active),
    isSeferiModeActive: Boolean(data.seferi_mode_active),
    isMediaCenterActive: Boolean(data.media_center_active),
    widgets_active: Boolean(data.widgets_active),
    community_active: Boolean(data.community_active),
    kids_mode_active: Boolean(data.kids_mode_active),
    premium_paywall_active: Boolean(data.premium_paywall_active),
    force_update_enabled: Boolean(data.force_update_active),
    min_version_code: Number(data.min_version_code || 1),
    godmode_features_revision: data.revision || 1
  };
}

function adsToRemoteConfig(data) {
  return {
    areAdsEnabled: Boolean(data.ads_active),
    isNativeAdEnabled: Boolean(data.native_active),
    isInterstitialEnabled: Boolean(data.interstitial_active),
    admobBannerAndroidId: data.banner_id_android || '',
    admobBannerIosId: data.banner_id_ios || '',
    admobNativeAndroidId: data.native_id_android || '',
    admobNativeIosId: data.native_id_ios || '',
    admobInterstitialAndroidId: data.interstitial_id_android || '',
    admobInterstitialIosId: data.interstitial_id_ios || '',
    interstitialFrequency: Number(data.frequency || 4),
    sensitiveScreensBlockedJson: data.sensitive_screens_blocked || [],
    godmode_ads_revision: data.revision || 1
  };
}

async function writeGodModeSyncMeta(docId, status, params, error = null) {
  await admin.firestore().collection('app_settings_meta').doc(`sync_${docId}`).set({
    docId,
    status,
    publishedKeys: Object.keys(params || {}),
    error: error ? String(error).slice(0, 800) : null,
    syncedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
}

export const syncGodModeThemeToRemoteConfig = onDocumentWritten(
  { region: REGION, document: 'app_settings/theme', timeoutSeconds: 60 },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    const data = after.data() || {};
    const params = themeToRemoteConfig(data);

    try {
      await publishGodModeRemoteConfig(params, 'app_settings/theme');
      await writeGodModeSyncMeta('theme', 'success', params);
    } catch (error) {
      await writeGodModeSyncMeta('theme', 'error', params, error.message);
      throw error;
    }
  }
);

export const syncGodModeFeaturesToRemoteConfig = onDocumentWritten(
  { region: REGION, document: 'app_settings/features', timeoutSeconds: 60 },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    const data = after.data() || {};
    const params = featuresToRemoteConfig(data);

    try {
      await publishGodModeRemoteConfig(params, 'app_settings/features');
      await writeGodModeSyncMeta('features', 'success', params);
    } catch (error) {
      await writeGodModeSyncMeta('features', 'error', params, error.message);
      throw error;
    }
  }
);

export const syncGodModeAdsToRemoteConfig = onDocumentWritten(
  { region: REGION, document: 'app_settings/ads', timeoutSeconds: 60 },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    const data = after.data() || {};
    const params = adsToRemoteConfig(data);

    try {
      await publishGodModeRemoteConfig(params, 'app_settings/ads');
      await writeGodModeSyncMeta('ads', 'success', params);
    } catch (error) {
      await writeGodModeSyncMeta('ads', 'error', params, error.message);
      throw error;
    }
  }
);

export const seedGodModeAppSettings = onCall(
  { region: REGION },
  async (request) => {
    const adminEmail = await assertAdmin(request);
    const db = admin.firestore();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const theme = {
      schemaVersion: 1,
      logoUrl: '',
      splashImageUrl: '',
      primaryColor: '#0E7C66',
      colors: {
        primary: '#0E7C66',
        secondary: '#E7C568',
        background: '#06111F',
        surface: '#102B25',
        text: '#F3FBF8'
      },
      fontStyle: {
        family: 'Inter',
        arabicFamily: 'Amiri',
        weight: '600',
        scale: 1
      },
      localization_override: {},
      revision: 1,
      updatedAt: now,
      updatedBy: adminEmail
    };

    const features = {
      schemaVersion: 1,
      ai_active: true,
      widgets_active: true,
      women_calendar_active: true,
      seferi_mode_active: true,
      media_center_active: true,
      community_active: true,
      kids_mode_active: true,
      premium_paywall_active: true,
      force_update_active: false,
      min_version_code: 1,
      revision: 1,
      updatedAt: now,
      updatedBy: adminEmail
    };

    const ads = {
      schemaVersion: 1,
      ads_active: true,
      native_active: true,
      interstitial_active: true,
      banner_id_android: '',
      banner_id_ios: '',
      native_id_android: '',
      native_id_ios: '',
      interstitial_id_android: '',
      interstitial_id_ios: '',
      frequency: 4,
      sensitive_screens_blocked: ['home', 'quran', 'qibla', 'ai_chat', 'kids_mode', 'adhan_alarm'],
      revision: 1,
      updatedAt: now,
      updatedBy: adminEmail
    };

    await Promise.all([
      db.collection('app_settings').doc('theme').set(theme, { merge: true }),
      db.collection('app_settings').doc('features').set(features, { merge: true }),
      db.collection('app_settings').doc('ads').set(ads, { merge: true })
    ]);

    return { ok: true };
  }
);
