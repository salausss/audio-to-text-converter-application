import { S3Client, GetObjectCommand, DeleteObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const s3 = new S3Client({});
const BUCKET = process.env.BUCKET_NAME;
const ASSEMBLYAI_API_KEY = process.env.ASSEMBLYAI_API_KEY;

function formatTimestamp(ms) {
  const totalSeconds = Math.floor(ms / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

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

    const audioUrl = await getSignedUrl(
      s3,
      new GetObjectCommand({ Bucket: BUCKET, Key: key }),
      { expiresIn: 600 }
    );

    const submitRes = await fetch("https://api.assemblyai.com/v2/transcript", {
      method: "POST",
      headers: {
        Authorization: ASSEMBLYAI_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        audio_url: audioUrl,
        speaker_labels: true,
      }),
    });
    const submitData = await submitRes.json();
    if (!submitRes.ok) throw new Error(JSON.stringify(submitData));

    const transcriptId = submitData.id;

    let result;
    for (let i = 0; i < 60; i++) {
      await new Promise((r) => setTimeout(r, 3000));
      const pollRes = await fetch(
        `https://api.assemblyai.com/v2/transcript/${transcriptId}`,
        { headers: { Authorization: ASSEMBLYAI_API_KEY } }
      );
      result = await pollRes.json();
      if (result.status === "completed" || result.status === "error") break;
    }

    if (result.status !== "completed") {
      throw new Error(result.error || "Transcription timed out");
    }

    // Return structured segments instead of one flat string, so the
    // frontend can render each turn as its own line with a timestamp
    const segments = (result.utterances || []).map((u) => ({
      speaker: u.speaker,
      time: formatTimestamp(u.start),
      text: u.text,
    }));

    await s3
      .send(new DeleteObjectCommand({ Bucket: BUCKET, Key: key }))
      .catch(() => {});

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ segments }),
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