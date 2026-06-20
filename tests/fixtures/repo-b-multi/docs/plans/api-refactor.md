# API refactor plan

## Goal

Tighten the public API for v2.

## Error envelope

Errors are returned flat:

```json
{ "code": "INVALID_INPUT", "message": "..." }
```

No wrapping object; clients branch on `code`.

## Endpoints

(elided for fixture purposes)
