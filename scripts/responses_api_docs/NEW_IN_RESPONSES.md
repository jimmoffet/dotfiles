# NEW\_IN\_RESPONSES

What's new and notable in the Responses API (concise, focused on Python SDK + REST examples).

## Unified multimodal endpoint

* One endpoint for text, images, files, and tools: POST /v1/responses. Use `input` items to mix modalities.

## Built-in hosted tools

* Models can call first-class tools during a single response: `web_search`, `file_search`, `image_generation`, `code_interpreter`, and MCP connectors.
* Enable tools via the `tools` parameter in create. Built-ins return typed tool-call items in the response for inspection.

Python example enabling web search:

```python
from openai import OpenAI
client = OpenAI()

resp = client.responses.create(
    model="gpt-4o",
    input="Find the latest on Copilot releases and summarize.",
    tools=[{"type":"web_search"}]
)
print(resp.output)
```

curl example:

```bash
curl https://api.openai.com/v1/responses \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o","input":"Find the latest on Copilot releases and summarize.","tools":[{"type":"web_search"}]}'
```

## Background / async responses

* Use `background: true` to run long-running tasks. Poll `GET /v1/responses/{response_id}` or use webhooks and the event stream.

## Structured outputs and function/tool calls

* Responses supports `response_format` for JSON schema outputs and function/tool calling in the same request. There is no separate parse endpoint — use `responses.create` with `response_format`.

## Conversation and previous response state

* `previous_response_id` gives a compact way to reference the last response for multi-turn flows. `conversation` objects provide explicit conversation storage.

## Prompt caching and cost controls

* `prompt_cache_key` lets you supply a stable key to increase cache hit rates. Check `usage` in responses for token breakdowns.

## Reasoning models and encrypted reasoning

* New reasoning models and `reasoning` options (effort, summary). You can request `reasoning.encrypted_content` to get encrypted reasoning tokens for later retrieval.

## Files API & uploads integration

* Files and uploads (`/v1/files`, `/v1/uploads`) are used with Responses for providing documents to the model. You can pass file references as input items or enable `file_search` to allow the model to find relevant files.

## Streaming & server-sent events

* Responses supports streaming over SSE for partial outputs and for tool-call events. Use `stream=true` on GET /v1/responses/{id} for incremental events.

## Security / best practices

* Keep API keys secret and rotate them. Use `safety_identifier` and `prompt_cache_key` appropriately. For PII-sensitive data, consider zero data retention settings and encrypted reasoning.

***

See other docs in this folder for expanded examples on Files, Tools, Images/Vision, Audio, and Caching.
