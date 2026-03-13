# Structured Outputs

Use `response_format` to ask the model to return machine-readable JSON that conforms to your schema.

## Python SDK example

```python
from openai import OpenAI
client = OpenAI()

schema = {
    "type": "object",
    "properties": {
        "title": {"type": "string"},
        "tags": {"type": "array", "items": {"type":"string"}}
    },
    "required": ["title"]
}

resp = client.responses.create(
    model="gpt-4o",
    input="Create metadata for this article: 'Deep Learning Basics and Best Practices'",
    response_format={"type":"json_schema","json_schema":{"name":"ArticleMeta","schema":schema}}
)

print(resp.output)
```

## Best practices

* Keep schemas small and explicit.
* Validate outputs and have a fallback if schema validation fails.
* Use `include` to request additional tool outputs (e.g., `file_search_call.results`).
