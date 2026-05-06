# Sample Messages for GenUI DevTools

Paste these into the **Raw JSON** editor in the GenUI DevTools tab, or use the
composer form. Send them in order — a surface must exist before you can update
it, and components must exist before you can send data model updates.

The catalog ID for `BasicCatalogItems` is always:
`https://a2ui.org/specification/v0_9/basic_catalog.json`

---

## 1. Minimal "Hello World"

### Step 1 — Create the surface
```json
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "demo",
    "catalogId": "https://a2ui.org/specification/v0_9/basic_catalog.json"
  }
}
```

### Step 2 — Add a Text component
```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "demo",
    "components": [
      {
        "id": "root",
        "component": "Text",
        "text": "Hello from the Surface Simulator!",
        "variant": "h2"
      }
    ]
  }
}
```

### Step 3 — Delete when done
```json
{
  "version": "v0.9",
  "deleteSurface": {
    "surfaceId": "demo"
  }
}
```

---

## 2. Form with a Button

Create a surface, lay out a column with a label and a button. The button
dispatches a `submitForm` action back through `onUserAction` so you can see it
arrive in your app's console.

### Create
```json
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "form",
    "catalogId": "https://a2ui.org/specification/v0_9/basic_catalog.json"
  }
}
```

### Add components
```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "form",
    "components": [
      {
        "id": "root",
        "component": "Column",
        "children": ["heading", "name-field", "submit-btn"]
      },
      {
        "id": "heading",
        "component": "Text",
        "text": "Book a Trip",
        "variant": "h3"
      },
      {
        "id": "name-field",
        "component": "TextField",
        "label": "Your name",
        "value": {"path": "/name"}
      },
      {
        "id": "submit-btn",
        "component": "Button",
        "child": "submit-label",
        "action": {
          "name": "submitForm",
          "context": ["name-field"]
        },
        "variant": "primary"
      },
      {
        "id": "submit-label",
        "component": "Text",
        "text": "Submit"
      }
    ]
  }
}
```

### Pre-fill the name field via data model
```json
{
  "version": "v0.9",
  "updateDataModel": {
    "surfaceId": "form",
    "path": "/name",
    "value": "Ada Lovelace"
  }
}
```

### Simulate the button tap (inject as userAction)
Switch message type to **userAction** in the composer, or paste into Raw JSON:
```json
{
  "name": "submitForm",
  "sourceComponentId": "submit-btn",
  "surfaceId": "form"
}
```

---

## 3. Card with a Checkbox

```json
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "checklist",
    "catalogId": "https://a2ui.org/specification/v0_9/basic_catalog.json"
  }
}
```

```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "checklist",
    "components": [
      {
        "id": "root",
        "component": "Column",
        "children": ["title", "opt1", "opt2", "opt3"]
      },
      {
        "id": "title",
        "component": "Text",
        "text": "Packing List",
        "variant": "h4"
      },
      {
        "id": "opt1",
        "component": "CheckBox",
        "label": "Passport",
        "value": {"path": "/packed/passport"}
      },
      {
        "id": "opt2",
        "component": "CheckBox",
        "label": "Adapter",
        "value": {"path": "/packed/adapter"}
      },
      {
        "id": "opt3",
        "component": "CheckBox",
        "label": "Camera",
        "value": {"path": "/packed/camera"}
      }
    ]
  }
}
```

### Pre-check an item via data model
```json
{
  "version": "v0.9",
  "updateDataModel": {
    "surfaceId": "checklist",
    "path": "/packed",
    "value": {
      "passport": true,
      "adapter": false,
      "camera": false
    }
  }
}
```

---

## 4. Slider

```json
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "slider-demo",
    "catalogId": "https://a2ui.org/specification/v0_9/basic_catalog.json"
  }
}
```

```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "slider-demo",
    "components": [
      {
        "id": "root",
        "component": "Column",
        "children": ["lbl", "sl"]
      },
      {
        "id": "lbl",
        "component": "Text",
        "text": "Budget"
      },
      {
        "id": "sl",
        "component": "Slider",
        "value": {"path": "/budget"},
        "min": 500,
        "max": 5000
      }
    ]
  }
}
```

### Set the slider value
```json
{
  "version": "v0.9",
  "updateDataModel": {
    "surfaceId": "slider-demo",
    "path": "/budget",
    "value": 2000
  }
}
```

---

## 5. Live data model update (streaming simulation)

Create the surface and components first (reuse the **form** example), then
fire these `updateDataModel` messages one after another to simulate the LLM
streaming values into the UI.

```json
{
  "version": "v0.9",
  "updateDataModel": {
    "surfaceId": "form",
    "path": "/name",
    "value": "Ada"
  }
}
```

```json
{
  "version": "v0.9",
  "updateDataModel": {
    "surfaceId": "form",
    "path": "/name",
    "value": "Ada Love"
  }
}
```

```json
{
  "version": "v0.9",
  "updateDataModel": {
    "surfaceId": "form",
    "path": "/name",
    "value": "Ada Lovelace"
  }
}
```

---

## Component wire format cheat sheet

All component properties are **flat** alongside `id` and `component`:

```json
{ "id": "my-id", "component": "ComponentName", "prop1": "value", "prop2": 42 }
```

String values that bind to the data model use a `{"path": "/json/pointer"}` object
instead of a plain string. Plain strings work as literals directly.

### Available components in BasicCatalogItems

| Component     | Required properties          | Notes                              |
|---------------|------------------------------|------------------------------------|
| `Text`        | `text`                       | `variant`: h1–h5, caption, body    |
| `Button`      | `child`, `action`            | `child` is another component ID    |
| `TextField`   | `label`, `value`             | `value` binds to data model path   |
| `CheckBox`    | `label`, `value`             | `value` is a boolean path          |
| `Column`      | `children`                   | Array of component IDs             |
| `Row`         | `children`                   | Array of component IDs             |
| `Slider`      | `value`                      | `min`, `max` default to 0/1        |
| `DateTimeInput` | `label`, `value`           | ISO 8601 string value              |
| `Image`       | `url`                        | String or path binding             |
| `Icon`        | `name`                       | Material icon name string          |
| `Card`        | `child`                      | Wraps one child component          |
| `ChoicePicker`| `label`, `value`, `options`  | Options is array of strings        |
| `Divider`     | (none)                       | Thin horizontal rule               |
