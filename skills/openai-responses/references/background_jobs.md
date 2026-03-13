# Background Jobs (long-running tasks)

Use `background: true` on create for long-running tasks. You receive a response ID immediately and can poll, stream events, or use webhooks.

## Start background job — Python SDK

```python
from openai import OpenAI
client = OpenAI()

resp = client.responses.create(
    model="gpt-4o",
    input="Perform a deep research summary about quantum computing trends (may take a while).",
    background=True
)

print('started', resp.id)

# Poll later:
status = client.responses.retrieve(resp.id)
print(status.status)
```

## REST / curl example

```bash
curl -X POST https://api.openai.com/v1/responses \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o","input":"Perform a deep research summary about quantum computing trends (may take a while).","background":true}'

# Poll:
curl https://api.openai.com/v1/responses/resp_123 \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

## Cancellation

* You can cancel background responses via POST /v1/responses/{response\_id}/cancel.
