# MIGRATION\_FROM\_COMPLETIONS\_API

This guide helps you migrate from the older Completions / Chat Completions APIs to the Responses API. Focus is on Python SDK examples and equivalent REST (curl) calls.

## Key differences

* Single unified endpoint: POST /v1/responses handles text, images, structured outputs, and tools.
* Multimodal inputs: supply text, images, or files in one request.
* Built-in tools & function calling: the model can call web\_search, file\_search, code\_interpreter, and custom function calls inside a single response.
* Stateful options: use `previous_response_id` for simple turn-by-turn state or `conversation` objects for explicit conversation storage.
* Background/async execution: `background: true` for long-running jobs (poll or webhook).

## Mapping Chat/Completions concepts -> Responses

* Chat messages -> `input` items. Each message (system/developer, user, assistant) becomes a message item with `content` array entries of type `input_text`, or `input_image`, etc.
* `system` messages -> use the `instructions` field or include developer/system role as the first input item.
* `user` messages -> `input` message items with role `user`.
* Role-based responses: output items include messages with `role: assistant` and `content` elements.

## Simple examples

### Chat Completions (old) — Python (example)

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

resp = client.chat.completions.create(
    model="gpt-4o", 
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Write a 2-line haiku about coffee."}
    ]
)
print(resp.choices[0].message.content)
```

### Equivalent using Responses — Python SDK

```python
from openai import OpenAI
import os

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

response = client.responses.create(
    model="gpt-4o",
    input=[
        {
            "type": "message",
            "role": "user",
            "content": [{"type": "input_text", "text": "Write a 2-line haiku about coffee."}]
        }
    ]
)

# The response output text will usually be available under response.output
print(response.output[0].content[0].text)
```

### REST / curl equivalent

curl example (Chat Completions old):

```bash
curl https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{"model":"gpt-4o","messages":[{"role":"system","content":"You are a helpful assistant."},{"role":"user","content":"Write a 2-line haiku about coffee."}]}'
```

curl example (Responses):

```bash
curl https://api.openai.com/v1/responses \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{"model":"gpt-4o","input":[{"type":"message","role":"user","content":[{"type":"input_text","text":"Write a 2-line haiku about coffee."}]}]}'
```

## Structured outputs (parsing)

Responses uses `response_format` (e.g. `json_schema`) to get machine-parseable outputs. There is no separate "parse" endpoint — use `responses.create` with the appropriate `response_format`.

Python example (structured JSON schema):

```python
schema = {
    "type": "object",
    "properties": {
        "title": {"type": "string"},
        "summary": {"type": "string"}
    },
    "required": ["title", "summary"]
}

resp = client.responses.create(
    model="gpt-4o",
    input="Summarize the following article:",
    response_format={"type":"json_schema","json_schema": {"name":"ArticleSummary","schema": schema}}
)

# parsed output will be in resp.output with the JSON matching the schema
print(resp.output)
```

## Conversation state and multi-turn behavior

To carry state across turns you can either:

* Use `previous_response_id` to reference the last response (quick turn-to-turn behavior).
* Use `conversation` and add items to conversation; Responses will prepend conversation items automatically.

Example: continuing a conversation in Python SDK

```python
first = client.responses.create(model="gpt-4o", input="What's the weather like in Paris?")
second = client.responses.create(model="gpt-4o", previous_response_id=first.id, input="And tomorrow?")
```

## Tools and function calls

Responses supports built-in tools (web\_search, file\_search, code\_interpreter) and custom function calls. Use the `tools` parameter to enable built-ins and `functions` (or function-like definitions) for custom calls.

## Background jobs (long-running)

For long-running or expensive tasks, set `background: true` on create. You will receive a response id to poll or receive webhook events.

## Files and uploads

Use the Files API (`/v1/files` and `/v1/uploads`) to upload PDFs, docs, etc. Pass file references as input items (type `item_reference`) or as `file` inputs depending on the SDK.

## Checklist for migration

1. Replace chat/completions calls with `responses.create` and map messages -> input items.
2. Replace function calling usage with Responses' function/tool model or built-ins as needed.
3. Use `response_format` for structured parsing rather than separate parser endpoints.
4. Review cost model and token usage fields returned by responses (`usage` object).
5. Add tests for outputs, and pin models to avoid snapshot differences.

***

Notes: This file focuses on examples in Python and curl. See other docs in this folder for tools, files, images, and background-job recipes.
