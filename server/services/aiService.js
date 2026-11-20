import fs from 'fs';
import { GoogleGenAI } from '@google/genai';

const runOfflineTriage = (title, description, building) => {
  const text = `${title} ${description}`.toLowerCase();

  let category = 'Civil & Structural';
  let severity = 'MEDIUM';
  let estimatedResolutionTime = '4 hours';
  let safetyAdvisory = 'Keep a safe perimeter around the affected zone until maintenance arrives.';

  if (/spark|wire|short circuit|fire|smoke|shock|voltage|panel|breaker|power|light|surge/.test(text)) {
    category = 'Electrical Safety';
    if (/spark|fire|smoke|exposed|shock|burning|surge/.test(text)) {
      severity = 'CRITICAL';
      estimatedResolutionTime = '20 mins';
      safetyAdvisory = 'DANGER: Do not touch exposed wiring or nearby metal fixtures. Evacuate immediate vicinity and alert floor security.';
    } else {
      severity = 'HIGH';
      estimatedResolutionTime = '1 hour';
      safetyAdvisory = 'Avoid operating switches on this circuit until electrical staff isolate the breaker.';
    }
  } else if (/water|leak|pipe|flood|burst|tap|drain|overflow|washroom|restroom|downspout/.test(text)) {
    category = 'Plumbing & Water';
    if (/burst|flood|gushing|electrical|overflow/.test(text)) {
      severity = 'HIGH';
      estimatedResolutionTime = '45 mins';
      safetyAdvisory = 'Slippery surface hazard. Avoid walking through pooled water, especially near power outlets.';
    } else {
      severity = 'MEDIUM';
      estimatedResolutionTime = '2 hours';
      safetyAdvisory = 'Watch for wet floors and use alternate washroom facilities in the adjacent wing.';
    }
  } else if (/wifi|internet|router|projector|server|network|lan|smartboard|lab pc|hdmi/.test(text)) {
    category = 'IT & Network';
    severity = /server|exam|lab/.test(text) ? 'HIGH' : 'MEDIUM';
    estimatedResolutionTime = '1 hour';
    safetyAdvisory = 'Do not unplug rack cables or reset network switches manually; IT support has been paged.';
  } else if (/ac|air condition|cooling|ventilation|hvac|heat|thermostat|chiller/.test(text)) {
    category = 'HVAC';
    severity = 'LOW';
    estimatedResolutionTime = '3 hours';
    safetyAdvisory = 'Ensure classroom windows are open for cross-ventilation until HVAC technicians inspect the compressor.';
  } else if (/garbage|trash|spill|dirty|clean|sanitation|odor|pest/.test(text)) {
    category = 'Sanitation';
    severity = /bio|chemical|glass|blood/.test(text) ? 'HIGH' : 'LOW';
    estimatedResolutionTime = '1 hour';
    safetyAdvisory = 'Avoid direct contact with the spill; housekeeping dispatch has been notified.';
  } else if (/gate|lock|cctv|intruder|access|guard|door|broken glass|security|bollard/.test(text)) {
    category = 'Security Hazard';
    severity = 'HIGH';
    estimatedResolutionTime = '30 mins';
    safetyAdvisory = 'Report immediately to the nearest campus security desk and avoid leaving valuables unattended.';
  } else if (/crack|wall|ceiling|tile|floor|railing|stair|roof|bench/.test(text)) {
    category = 'Civil & Structural';
    if (/falling|collapse|ceiling|deep crack|railing/.test(text)) {
      severity = 'CRITICAL';
      estimatedResolutionTime = '30 mins';
      safetyAdvisory = 'CRITICAL STRUCTURAL ALERT: Clear the area beneath the damaged structure immediately.';
    } else {
      severity = 'MEDIUM';
      estimatedResolutionTime = '6 hours';
      safetyAdvisory = 'Exercise caution near damaged flooring or fixtures.';
    }
  }

  return {
    category,
    severity,
    aiSummary: `[${severity}] ${category} incident reported at ${building}: ${title.trim()}.`,
    estimatedResolutionTime,
    safetyAdvisory,
    triageEngineUsed: 'OFFLINE_NLP_HEURISTIC',
  };
};

export const analyzeIncident = async ({ title, description, building, imagePath, mimeType }) => {
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey || apiKey.trim() === '') {
    return runOfflineTriage(title, description, building);
  }

  try {
    const ai = new GoogleGenAI({ apiKey });

    const prompt = `You are CampusFlow AI, an autonomous university facility triage & safety intelligence system.
Analyze this campus incident report and optional photo evidence.
Return ONLY a valid raw JSON object (no markdown fences) with these exact keys:
- "category": strictly one of ["Electrical Safety", "Plumbing & Water", "IT & Network", "Civil & Structural", "HVAC", "Sanitation", "Security Hazard"]
- "severity": strictly one of ["CRITICAL", "HIGH", "MEDIUM", "LOW"]
- "aiSummary": concise 1-sentence technical dispatch brief for maintenance engineers
- "estimatedResolutionTime": realistic string like "25 mins", "1 hour", "4 hours"
- "safetyAdvisory": direct, actionable immediate safety instruction for the student on scene

Incident Details:
- Building: ${building}
- Title: ${title}
- Description: ${description}`;

    const contents = [prompt];

    if (imagePath && fs.existsSync(imagePath)) {
      const imageBytes = fs.readFileSync(imagePath);
      contents.push({
        inlineData: {
          data: imageBytes.toString('base64'),
          mimeType: mimeType || 'image/jpeg',
        },
      });
    }

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents,
      config: {
        responseMimeType: 'application/json',
        temperature: 0.2,
      },
    });

    const parsed = JSON.parse(response.text);

    return {
      category: parsed.category || 'Civil & Structural',
      severity: parsed.severity || 'MEDIUM',
      aiSummary: parsed.aiSummary || `${title} reported in ${building}.`,
      estimatedResolutionTime: parsed.estimatedResolutionTime || '2 hours',
      safetyAdvisory: parsed.safetyAdvisory || 'Keep clear of the hazard area until staff arrive.',
      triageEngineUsed: 'GEMINI_MULTIMODAL',
    };
  } catch (error) {
    console.warn(`[AI Triage Fallback] ${error.message}, switching to Offline NLP Engine.`);
    return runOfflineTriage(title, description, building);
  }
};

export const generateSafetyChatReply = async (message) => {
  const apiKey = process.env.GEMINI_API_KEY;

  if (apiKey && apiKey.trim() !== '') {
    try {
      const ai = new GoogleGenAI({ apiKey });
      const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: `You are CampusFlow AI Safety Copilot for Presidency University, Bengaluru. Provide a concise, calm, practical safety and troubleshooting response (max 3-4 sentences) for this student query: "${message}".`,
      });
      return { reply: response.text, source: 'GEMINI_AI' };
    } catch (err) {
      console.warn(`[Chat Fallback] ${err.message}`);
    }
  }

  const q = message.toLowerCase();
  if (/fire|smoke|spark|electric|shock/.test(q)) {
    return {
      reply: '1. Do NOT touch any electrical panels, wires, or water near the source.\n2. Evacuate the room immediately and trigger the nearest fire alarm pull station.\n3. Call Campus Security Emergency Desk (Ext. 100) and log a CRITICAL ticket.',
      source: 'OFFLINE_COPILOT',
    };
  }
  if (/water|leak|flood|pipe/.test(q)) {
    return {
      reply: '1. Avoid stepping in standing water near wall sockets.\n2. Close local isolation valves if safely accessible.\n3. Log a Plumbing & Water ticket with a photo for immediate crew dispatch.',
      source: 'OFFLINE_COPILOT',
    };
  }
  return {
    reply: 'Keep a safe distance from any physical hazard. Submit a report with a photo for instant AI severity triage and live dispatch to Presidency University Facility Operations.',
    source: 'OFFLINE_COPILOT',
  };
};