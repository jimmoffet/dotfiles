# Create vs Parse (structured parsing)

Responses unifies generation and parsing into the same endpoint. There is no separate "parse" endpoint — use `responses.create` with `response_format` to enforce structured outputs.

## Use cases

* Simple generation: omit `response_format` and parse free text from `response.output`.
* Structured parsing: provide `response_format` with `json_schema` to return validated JSON.

## Python SDK — structured parse example

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

schema = {
    "type": "object",
    "properties": {
        "name": {"type": "string"},
        "email": {"type": "string"}
    },
    "required": ["name","email"]
}

resp = client.responses.create(
    model="gpt-4o",
    input="Extract a name and email from: 'Contact: Ada Lovelace <ada@example.com>'",
    response_format={"type":"json_schema","json_schema":{"name":"Contact","schema":schema}}
)

print(resp.output)
```

## curl example

```bash
curl https://api.openai.com/v1/responses \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o","input":"Extract a name and email from: \"Contact: Ada Lovelace <ada@example.com>\"","response_format":{"type":"json_schema","json_schema":{"name":"Contact","schema":{"type":"object","properties":{"name":{"type":"string"},"email":{"type":"string"}},"required":["name","email"]}}}}'
```

## Notes

* `response_format` ensures the model emits valid JSON matching your schema; handle parse errors and `incomplete_details` in production.
