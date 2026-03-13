# Text Generation with Responses

This document shows how to use the Responses API for text generation with the Python SDK and REST (curl).

## Simple text generation — Python SDK

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

resp = client.responses.create(
    model="gpt-4o",
    input=[
        {"type":"message","role":"user","content":[{"type":"input_text","text":"Write a friendly 3-sentence product blurb for a noise-cancelling headset."}]}
    ],
    max_output_tokens=150
)

print(resp.output[0].content[0].text)
```

## REST / curl example

```bash
curl https://api.openai.com/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{"model":"gpt-4o","input":[{"type":"message","role":"user","content":[{"type":"input_text","text":"Write a friendly 3-sentence product blurb for a noise-cancelling headset."}]}],"max_output_tokens":150}'
```

## Tips

* Pin models to stable version IDs for reproducible behavior.
* Use `temperature`, `top_p`, and `max_output_tokens` to control creativity and length.
