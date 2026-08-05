import {
  S3Client,
  GetObjectCommand,
  DeleteObjectCommand,
} from "@aws-sdk/client-s3";

const s3 = new S3Client({});
const BUCKET = process.env.BUCKET_NAME;
const GROQ_API_KEY = process.env.GROQ_API_KEY;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
};

export const handler = async (event) => {
  if (event.requestContext?.http?.method === "OPTIONS") {
    return { statusCode: 200, headers: CORS_HEADERS, body: "" };
  }

  try {
    const { key } = JSON.parse(event.body || "{}");
    if (!key) {
      return {
        statusCode: 400,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: "Missing 'key'" }),
      };
    }

    // Pull the uploaded audio file down from S3
    const obj = await s3.send(
      new GetObjectCommand({ Bucket: BUCKET, Key: key })
    );
    const audioBuffer = Buffer.from(await obj.Body.transformToByteArray());

    // Build multipart form for Groq's OpenAI-compatible transcription endpoint
    const form = new FormData();
    form.append("file", new Blob([audioBuffer]), "audio.mp3");
    form.append("model", "whisper-large-v3-turbo");

    const res = await fetch(
      "https://api.groq.com/openai/v1/audio/transcriptions",
      {
        method: "POST",
        headers: { Authorization: `Bearer ${GROQ_API_KEY}` },
        body: form,
      }
    );

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`Groq API error: ${res.status} ${errText}`);
    }

    const data = await res.json();

    // Delete the temp file immediately after transcribing — don't wait for
    // the 1-day lifecycle rule, keeps storage cost at essentially zero.
    await s3
      .send(new DeleteObjectCommand({ Bucket: BUCKET, Key: key }))
      .catch(() => {});

    return {
      statusCode: 200,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      body: JSON.stringify({ text: data.text }),
    };
  } catch (err) {
    console.error(err);
    return {
      statusCode: 500,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      body: JSON.stringify({ error: "Transcription failed" }),
    };
  }
};
