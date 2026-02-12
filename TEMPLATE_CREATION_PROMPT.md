# PROMPT: Создание шаблонов Power Platform DevKit Templates

## КОНТЕКСТ

Ты работаешь с проектом `tools-devkit-templates` — набором dotnet new шаблонов для code-first разработки Power Platform / Dataverse решений.

Корень проекта: текущая рабочая директория или путь, который укажет пользователь.
Шаблоны расположены в: `src/Dataverse/templates/`
Builder-инструмент: `tools/TALXIS.DevKit.Templates.Builder/`

Перед созданием любого шаблона **обязательно просканируй**:
1. `src/Dataverse/templates/` — список всех существующих шаблонов (чтобы не дублировать и соблюдать naming convention)
2. Ближайший по смыслу существующий шаблон — прочитай его `template.json`, все скрипты и temp-файлы целиком
3. `tools/TALXIS.DevKit.Templates.Builder/TemplateAssets/` — embedded ресурсы (symbols.json, postActions.json, скрипты)
4. Файл `TALXIS.DevKit.Templates.Dataverse.csproj` — чтобы убедиться, что новый шаблон попадёт в пакет

---

## АРХИТЕКТУРА ШАБЛОНОВ

### Структура каждого шаблона

```
pp-<shortname>/
  .template.config/
    template.json          ← Конфигурация: символы, параметры, postActions
  .template.scripts/       ← PowerShell скрипты (выполняются как postActions)
    *.ps1
  .template.temp/          ← Временные XML/файлы (опционально — можно создавать из скриптов)
    *.xml
  SolutionDeclarationsRoot/ ← Файлы-шаблоны, копируемые в проект (опционально)
    ...
```

### Как работает dotnet new template engine

1. **Копирование**: Копирует файлы шаблона в `--output` или текущую директорию
2. **Подстановка**: Проходит по ВСЕМ файлам (включая .ps1!) и заменяет строки-placeholder'ы на значения параметров. Замена — простой текстовый find-replace, НЕ учитывает синтаксис языка
3. **PostActions**: Последовательно запускает PowerShell скрипты

**Критично**: template engine заменяет placeholder'ы ДО запуска скриптов. Поэтому в скриптах можно использовать строки-placeholder'ы — к моменту выполнения они уже будут заменены на реальные значения.

### template.json — Формат

```json
{
  "$schema": "http://json.schemastore.org/template",
  "author": "NETWORG",
  "identity": "TALXIS.DevKit.Templates.Dataverse.<Category>.<Name>",
  "name": "Power Platform: <Readable Name>",
  "shortName": "pp-<shortname>",
  "sourceName": "examplecustomentityattribute",
  "preferNameDirectory": false,
  "tags": { "language": "XML", "type": "item" },
  "symbols": { ... },
  "postActions": [ ... ]
}
```

### Типы символов (symbols)

#### 1. parameter — пользовательский ввод
```json
"MyParam": {
  "type": "parameter",
  "datatype": "text",           // text | string | choice | bool
  "isRequired": true,
  "defaultValue": "...",
  "replaces": "placeholderstring",  // ЭТА строка будет заменена во всех файлах
  "fileRename": "placeholderstring", // Также переименовывает файлы (опционально)
  "description": "..."
}
```

Для choice:
```json
"FormType": {
  "type": "parameter",
  "datatype": "choice",
  "replaces": "formtypeexample",
  "defaultValue": "unknown",
  "choices": [
    { "choice": "main" },
    { "choice": "quick" },
    { "choice": "dialog" },
    { "choice": "unknown" }
  ]
}
```

#### 2. generated — автоматически генерируемые значения

GUID генератор:
```json
"controluniqueidexample": {
  "type": "generated",
  "generator": "guid",
  "parameters": { "defaultFormat": "d" },
  "replaces": "controluniqueidexample"
}
```

Switch генератор (маппинг choice → значение):
```json
"classid": {
  "type": "generated",
  "generator": "switch",
  "replaces": "exampleclassid",
  "parameters": {
    "datatype": "string",
    "cases": [
      { "condition": "(ControlType == \"Text\")", "value": "4273EDBD-AC1D-40d3-9FB2-095C621B552D" },
      { "condition": "(ControlType == \"WholeNumber\")", "value": "C3EFE0C3-0EC6-42be-8349-CBD9079DFD8E" }
    ]
  }
}
```

#### 3. computed — вычисляемые boolean
```json
"AddMainForm": {
  "type": "computed",
  "value": "(FormType == \"main\")"
}
```

### PostActions — формат

```json
"postActions": [
  {
    "actionId": "3A7C4B45-1F5D-4A30-959A-51B88E82B5D2",
    "args": {
      "executable": "pwsh",
      "args": "-noprofile -executionpolicy bypass -File \"./.template.scripts/ScriptName.ps1\"",
      "redirectStandardOutput": "false"
    },
    "manualInstructions": [{ "text": "Description" }],
    "continueOnError": false,
    "description": "Description"
  }
]
```

**actionId всегда один и тот же**: `3A7C4B45-1F5D-4A30-959A-51B88E82B5D2` (run executable).

---

## КАТЕГОРИИ ШАБЛОНОВ И ПАТТЕРНЫ

### A. Шаблоны форм (hierarchy: form → tab → column → section → row → cell → control)

Все шаблоны форм используют **Add.ps1** для навигации по XML-иерархии формы и вставки новых элементов. Общие параметры:

| Параметр | Назначение |
|---|---|
| SolutionRootPath | Путь к корню solution (required). Заменяет "SolutionDeclarationsRoot" |
| EntitySchemaName | Логическое имя entity. Заменяет "exampleentityname" |
| FormType | Тип формы: main, quick, dialog, unknown. Заменяет "formtypeexample" |
| FormId | GUID формы. Заменяет "formguididexample" |
| TabId / TabIndex | Идентификация вкладки |
| ColumnIndex | Индекс колонки в вкладке |
| SectionId / SectionIndex | Идентификация секции |
| RowIndex | Индекс строки |

**LocateForm.ps1** — общий скрипт поиска формы. Четыре сценария:
1. Все unknown → ищет последний изменённый XML в FormXml/main или quickCreate
2. FormType или EntityName unknown → ищет по FormId (имя файла)
3. FormId unknown → ищет последний XML в указанной entity/formType
4. Все известны → прямой путь: `./SolutionDeclarationsRoot/Entities/{entity}/FormXml/{type}/{id}.xml`

### B. Шаблоны стандартных контролов (pp-form-control)

Добавляют `<control>` элемент в ячейку формы. Ключевые classid:

| ControlType | ClassId |
|---|---|
| Text | 4273EDBD-AC1D-40d3-9FB2-095C621B552D |
| MultilineText | E0DECE4B-6FC8-4a8f-A065-082708572369 |
| WholeNumber | C3EFE0C3-0EC6-42be-8349-CBD9079DFD8E |
| Decimal | C3EFE0C3-0EC6-42be-8349-CBD9079DFD8E |
| Float | 0D2C745A-E5A8-4c8f-BA63-C6D3BB604660 |
| Currency | 533B9E00-756B-4312-95A0-DC888637AC78 |
| DateTime | 5B773807-9FB2-42db-97C3-7A91EFF8ADFF |
| Lookup | 270BD3DB-D9AF-4782-9025-509E298DEC0A |
| OptionSet | 3EF39988-22BB-4F0B-BBBE-64B5A3748AEE |
| SubGrid | E7A81278-8635-4D9E-8D4D-59480B391C5B |
| Button | 00ad73da-bd4d-49c6-88a8-2f4f4cad4a20 |

### C. Шаблоны кастомных контролов (pp-customcontrol-*)

Добавляют PCF (Power Component Framework) контрол на форму через `controlDescriptions` блок.

**XML-структура, которую создают:**
```xml
<form>
  ...
  <controlDescriptions>
    <controlDescription forControl="{ControlId}">
      <customControl formFactor="0" name="{PublisherPrefix}_{ControlName}">
        <parameters>
          <paramName type="ParamType">paramValue</paramName>
        </parameters>
      </customControl>
    </controlDescription>
  </controlDescriptions>
</form>
```

**formFactor**: 0 = Web, 1 = Tablet, 2 = Phone. Для полного покрытия шаблон вызывается 3 раза.

**Два подхода:**

1. **Специфичный шаблон** (pp-customcontrol-checkbox, pp-customcontrol-addresscontrol и т.д.):
   - Параметры PCF-контрола статически определены в template.json как символы
   - Placeholder'ы подставляются template engine
   - customcontrolparameters.xml содержит placeholder'ы, которые заменяются
   - RemoveUnusedNodes.ps1 убирает параметры, оставленные как `defaulttemplateexample`
   - AddCustomControlParameters.ps1 вставляет XML в форму
   - Имя контрола захардкожено в AddCustomControlParameters.ps1 строка 4

2. **Универсальный шаблон** (pp-customcontrol-generic):
   - Имя контрола — параметр `CustomControlName`
   - Параметры — JSON-строка `CustomControlParameters`
   - GenerateParametersXml.ps1 парсит JSON, создаёт .template.temp/ и customcontrolparameters.xml
   - Далее стандартный flow: RemoveUnusedNodes → AddCustomControlParameters → Cleanup

**Placeholder-соглашения для customcontrol:**

| Placeholder | Символ | Где используется |
|---|---|---|
| `customcontrolnameexample` | CustomControlName | AddCustomControlParameters.ps1 строка 4 |
| `customcontrolparametersexample` | CustomControlParameters | GenerateParametersXml.ps1 строка 1 |
| `examplepublisherprefix` | PublisherPrefix | AddCustomControlParameters.ps1 строка 4 |
| `customcontrolformfactorexample` | CustomControlFormFactor | AddCustomControlParameters.ps1 строка 3 |
| `controlDescriptionIdexample` | ControlId | AddCustomControlParameters.ps1 строка 2 |

**AddCustomControlParameters.ps1 — строка 4 формирует имя контрола:**
```powershell
$customControlName="examplepublisherprefix_customcontrolnameexample"
```
После подстановки: `$customControlName="udpp_UdppControls.QuantityIndicator"`

**Формат customcontrolparameters.xml:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<parameters>
  <paramName type="ParamType">paramValue</paramName>
</parameters>
```

**AddCustomControlParameters.ps1 импортирует ДОЧЕРНИЕ элементы из customcontrolparameters.xml (НЕ корневой `<parameters>`):**
```powershell
foreach ($childNode in $parameterXml.DocumentElement.ChildNodes) {
    $importedNode = $entityXml.ImportNode($childNode, $true)
    $parametersNode.AppendChild($importedNode) | Out-Null
}
```
**ВАЖНО**: Это исправленная версия. Оригинальные 68 шаблонов используют `ImportNode($parameterXml.DocumentElement, $true)` — что создаёт вложенный `<parameters><parameters>...</parameters></parameters>`. В generic-шаблоне это исправлено.

### D. Параметры контролов (pp-control-parameters)

Добавляют `<parameters>` внутрь `<control>` элемента (НЕ в controlDescriptions).
Это для стандартных параметров Lookup, SubGrid, OptionSet и т.д.

### E. Прочие шаблоны

- `pp-entity` — создание entity (таблицы)
- `pp-entity-attribute` — добавление атрибутов
- `pp-entity-view` — создание views
- `pp-solution` — инициализация solution через PAC CLI
- `pp-app-model` — model-driven app
- `pp-sitemap-*` — навигация sitemap
- `pp-security-role` — роли безопасности
- `pp-plugin` — серверные плагины
- `pp-script-library` — TypeScript web resources
- `pp-bpf` — Business Process Flows
- `pp-ribbon-*` — кастомизация ribbon

---

## ОБЩИЕ СКРИПТЫ (переиспользуются между шаблонами)

### LocateForm.ps1
Находит XML файл формы. Placeholder'ы: `SolutionDeclarationsRoot`, `exampleentityname`, `formtypeexample`, `formguididexample`.

### Add.ps1 (для form hierarchy шаблонов)
Навигирует XML-иерархию формы по параметрам (TabId/TabIndex → ColumnIndex → SectionId/SectionIndex → RowIndex) и вставляет новый элемент (импорт из .template.temp/).

### RemoveUnusedNodes.ps1
Удаляет ноды с текстом `defaulttemplateexample` или `{defaulttemplateexample}` из customcontrolparameters.xml.

### Cleanup.ps1
```powershell
Remove-Item .template.scripts -Recurse -Force
Remove-Item .template.temp -Recurse -Force
```

### AddCustomControlParameters.ps1
Создаёт `controlDescriptions → controlDescription → customControl → parameters` в форме XML. Импортирует параметры из customcontrolparameters.xml.

### AddControlParameters.ps1 (для pp-control-parameters)
Находит `<control>` элемент внутри ячейки формы и добавляет `<parameters>` внутрь него.

### AddToSolutionXml.ps1
Добавляет компонент в Solution.xml.

---

## BUILDER TOOL

`tools/TALXIS.DevKit.Templates.Builder/` — C# консольное приложение, генерирующее специфичные pp-customcontrol шаблоны из ControlManifest.Input.xml PCF-контрола.

**Что делает:**
1. `ImputXmlParser.cs` — парсит ControlManifest.Input.xml, извлекает constructor, display-name-key, property-ноды
2. `TemplateParameterModel.cs` — модель параметра. Генерирует:
   - placeholder `replaces`: `{nodeName}exampletype{nodeType}` (lowercase, без спецсимволов)
   - XML ноду: `<nodeName type="nodeType" static="true">placeholder</nodeName>`
   - Символы: обычные (text) или enum (switch generator)
3. `TemplateJsonBuilder.cs` — собирает template.json из header + parameters + embedded symbols.json + postActions.json
4. `TemplateBuilder.cs` — оркестратор:
   - Генерирует template.json
   - Копирует embedded скрипты, заменяет `customcontrolnameexample` на реальное имя контрола
   - Генерирует customcontrolparameters.xml

**Embedded ресурсы:**
- `TemplateAssets/.template.scripts/AddCustomControlParameters.ps1` — строка 4: `$customControlName="examplepublisherprefix_customcontrolnameexample"`
- `TemplateAssets/.template.scripts/LocateForm.ps1`
- `TemplateAssets/.template.scripts/RemoveUnusedNodes.ps1`
- `TemplateAssets/.template.scripts/Cleanup.ps1`
- `TemplateAssets/symbols.json` — 7 общих символов
- `TemplateAssets/postActions.json` — 3 стандартных postAction

---

## ИНСТРУКЦИЯ ПО СОЗДАНИЮ НОВОГО ШАБЛОНА

### Шаг 0: Разведка
- Просканируй `src/Dataverse/templates/` — определи, есть ли уже похожий шаблон
- Прочитай ближайший существующий шаблон ЦЕЛИКОМ (template.json + все скрипты + все temp файлы)
- Пойми, в какую категорию попадает новый шаблон (form hierarchy / control / customcontrol / entity / другое)

### Шаг 1: Определи структуру
- Какие параметры нужны пользователю?
- Какие файлы создаются / модифицируются?
- Какие скрипты можно переиспользовать (LocateForm.ps1, Cleanup.ps1)?
- Нужна ли папка .template.temp или скрипты создадут файлы сами?

### Шаг 2: Создай template.json
- `identity`: `TALXIS.DevKit.Templates.Dataverse.<Category>.<Name>`
- `shortName`: `pp-<kebab-case-name>`
- `author`: `NETWORG`
- Для каждого параметра определи: тип (parameter/generated/computed), datatype, placeholder (replaces), обязательность
- Placeholder naming convention: `<имя>example<суффикс>` (например `exampleentityname`, `formtypeexample`, `controlDescriptionIdexample`)
- PostActions: всегда используй `actionId: "3A7C4B45-1F5D-4A30-959A-51B88E82B5D2"`, `executable: "pwsh"`

### Шаг 3: Создай/скопируй скрипты
- Переиспользуй LocateForm.ps1, Cleanup.ps1, RemoveUnusedNodes.ps1 если применимо
- Новые скрипты пиши на PowerShell (pwsh)
- Помни: placeholder'ы в скриптах будут заменены ДО выполнения
- Используй `[xml]` для работы с XML
- Используй `$entityXml.CreateElement()`, `SetAttribute()`, `AppendChild()` для создания нод
- Используй `$entityXml.ImportNode($node, $true)` для импорта из другого XML

### Шаг 4: Создай temp файлы (если нужны)
- Или создавай их динамически из скриптов (предпочтительно — меньше файлов в шаблоне)
- Формат для параметров контролов:
```xml
<?xml version="1.0" encoding="utf-8"?>
<parameters>
  <paramName type="ParamType">paramValue</paramName>
</parameters>
```

### Шаг 5: Проверь
- `dotnet new install .` из корня Dataverse templates
- `dotnet new <shortName> --<params>` в тестовом проекте
- Проверь результирующий XML — сравни с эталоном

---

## КОНКРЕТНЫЕ ПРИМЕРЫ

### Пример: Создание специфичного pp-customcontrol шаблона

Если нужен шаблон для конкретного PCF-контрола с предопределёнными параметрами:

1. Скопируй `pp-customcontrol-checkbox` как основу
2. В template.json:
   - Замени identity, name, shortName
   - Замени/добавь символы для параметров контрола
   - Для Enum-параметров: создай choice-символ + switch-generated символ
3. В AddCustomControlParameters.ps1 строка 4:
   - Замени `TALXIS.PCF.Checkbox` на имя твоего контрола
4. Создай customcontrolparameters.xml с нужными параметрами и placeholder'ами
5. Placeholder naming: `{paramName}exampletype{paramType}` (lowercase, no special chars)
   - Пример: параметр `bindingField` типа `TwoOptions` → placeholder `bindingfieldexampletypetwooptions`

### Пример: Использование generic шаблона

Для быстрого добавления любого PCF-контрола без создания отдельного шаблона:

```powershell
dotnet new pp-customcontrol-generic `
  --CustomControlName "TALXIS.PCF.MyControl" `
  --CustomControlParameters '[{"name":"field1","type":"SingleLine.Text","value":"talxis_field1"},{"name":"flag","type":"Enum","value":"Yes"}]' `
  --PublisherPrefix "talxis" `
  --CustomControlFormFactor "0" `
  --ControlId "guid-of-control" `
  --SolutionRootPath "Declarations" `
  --EntitySchemaName "talxis_myentity" `
  --FormType "main" `
  --FormId "guid-of-form"
```

Вызвать 3 раза с formFactor 0, 1, 2 для полного покрытия.

---

## ЧЕКЛИСТ ПЕРЕД ФИНАЛИЗАЦИЕЙ

- [ ] shortName уникален среди всех шаблонов
- [ ] identity уникален
- [ ] Все placeholder строки уникальны и не пересекаются с другими символами
- [ ] PostActions идут в правильном порядке (generate → remove → add → cleanup)
- [ ] Cleanup.ps1 удаляет .template.scripts И .template.temp
- [ ] Скрипты работают из рабочей директории шаблона (все пути относительные от --output)
- [ ] XML манипуляции используют ImportNode для дочерних элементов, а НЕ корневой элемент (чтобы избежать двойной вложенности)
