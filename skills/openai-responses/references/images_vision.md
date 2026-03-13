# Images & Vision

Responses supports image inputs and image-based reasoning. Pass images as `input` items (URL, base64, or file id) and request text outputs that reference visual content.

## Python SDK example (image + text)

```python
from openai import OpenAI
client = OpenAI()

resp = client.responses.create(
    model="gpt-4o",
    input=[
        {"type":"message","role":"user","content":[{"type":"input_text","text":"Describe the image."}]},
        {"type":"input_image","image_url":"https://example.com/photo.jpg"}
    ]
)

print(resp.output)
```

## REST / curl example

```bash
curl https://api.openai.com/v1/responses \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o","input":[{"type":"message","role":"user","content":[{"type":"input_text","text":"Describe the image."}]},{"type":"input_image","image_url":"https://example.com/photo.jpg"}]}'
```

## Notes

* `include` can request `message.input_image.image_url` to get canonical URLs for generated images.
* For image generation calls use the `image_generation` tool or Assistants/Images endpoints; confirm model support for vision features.
