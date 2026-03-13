# Files API & Uploads (best practices)

Use the Files API for storing documents that the model can reference via `file_search` or by passing file references to `responses.create`.

## Upload file — REST (curl)

```bash
curl -X POST https://api.openai.com/v1/files \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -F file=@"./document.pdf" \
  -F purpose="responses"
```

## Python SDK — referencing uploaded files in a response

```python
from openai import OpenAI
client = OpenAI()

# Pass a file as an input item reference
resp = client.responses.create(
    model="gpt-4o",
    input=[
        {"type":"item_reference","id":"file-abc123"},
        {"type":"message","role":"user","content":[{"type":"input_text","text":"Summarize the above document."}]}
    ],
)

print(resp.output)
```

## Best practices

* Prefer `file_search` for large corpora; allow the model to search instead of sending entire files inline.
* Respect file size limits and use the Uploads API for large multipart uploads.
* Tag and store file metadata to improve retrieval.
