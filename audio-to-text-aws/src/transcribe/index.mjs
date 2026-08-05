import {
  S3Client,
  GetObjectCommand,
  DeleteObjectCommand,
} from "@aws-sdk/client-s3";

const s3 = new S3Client({});
const BUCKET = process.env.BUCKET_NAME;
const GROQ_API_KEY = process.env.GROQ_API_KEY;

export const handler = async (event) => {
  if (event.requestContext?.http?.method === "OPTIONS") {
    return { statusCode: 200, body: "" };
  }

  try {
    const { key } = JSON.parse(event.body || "{}");
    if (!key) {
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ error: "Missing 'key'" }),
      };
    }

    const obj = await s3.send(
      new GetObjectCommand({ Bucket: BUCKET, Key: key })
    );
    const audioBuffer = Buffer.from(await obj.Body.transformToByteArray());

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

    await s3
      .send(new DeleteObjectCommand({ Bucket: BUCKET, Key: key }))
      .catch(() => {});

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: data.text }),
    };
  } catch (err) {
    console.error(err);
    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: "Transcription failed" }),
    };
  }
};