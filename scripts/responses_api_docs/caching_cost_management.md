# Caching & Cost Management

Strategies to reduce cost and improve latency when using Responses.

## Prompt caching

* Provide a stable `prompt_cache_key` to increase cache hit rates for repeated prompts. This replaces the legacy `user` field for caching.

## Token control

* Use `max_output_tokens`, `temperature`, and `top_p` to limit output size and variability.
* Inspect the `usage` object on the response to track input, output, and reasoning tokens.

## Tool & image costs

* Built-in tools and image/vision processing may incur additional costs. Limit `max_tool_calls` and prefer smaller image sizes.

## Example: set prompt cache key (Python)

```python
from openai import OpenAI
client = OpenAI()

resp = client.responses.create(
    model="gpt-4o",
    input="Summarize the following FAQ...",
    prompt_cache_key="faq_v1:summary"
)

print(resp.usage)
```

## Best practices

* Cache results on your side for idempotent queries.
* Monitor `usage` and set budget alerts in the OpenAI dashboard.
* Use background jobs for expensive processing when interactive latency is not required.
