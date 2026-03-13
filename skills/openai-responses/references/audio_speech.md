# Audio & Speech

Responses integrates with audio endpoints for transcription and speech generation. For long audio or advanced TTS use the dedicated `/v1/audio` endpoints; Responses can include audio modalities in multimodal flows.

## Transcription (curl)

```bash
curl https://api.openai.com/v1/audio/transcriptions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F file=@"./meeting.mp3" \
  -F model="gpt-4o-transcribe"
```

## Python SDK example — requesting audio output in Responses (modalities)

```python
from openai import OpenAI
client = OpenAI()

resp = client.responses.create(
    model="gpt-4o",
    input="Read this short poem in a warm voice.",
    # Some models support audio output when modalities requested by the SDK or Realtime API
)

print(resp.output)
```

## Notes

* Use dedicated `/v1/audio` endpoints for TTS and transcription production workloads.
* Streaming transcriptions and diarization are available via `stream` and model-specific options.
