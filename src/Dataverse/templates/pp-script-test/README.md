# Power Platform: Script Test Template

This template creates a test project for Power Platform JavaScript/TypeScript web resources using Jest. It provides a complete testing infrastructure with Xrm API mocks, helper functions, and integration with .NET test framework.

## Overview

The `pp-script-test` template generates a test project configured for testing Dataverse web resources (form scripts, ribbon commands, etc.). It includes:

- Jest test framework with jsdom environment
- Xrm API mocks for Dataverse client-side API
- Helper functions for creating test objects (forms, attributes, controls)
- Web resource loader utility for testing your scripts
- .NET project integration for running tests via `dotnet test`
- Automatic npm package installation

## Prerequisites

- .NET SDK 8.0+ installed
- Node.js and npm installed
- PowerShell 7+ installed
- A script library project (web resources project)

## Usage

### Basic Usage

Create a script test project:

```console
dotnet new pp-script-test `
--output "tests/Script.Tests" `
--ScriptTestProjectName "Script.Tests" `
--ScriptLibraryPath "../src/Scripts.Warehouse" `
--allow-scripts yes
```

### Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `ScriptTestProjectName` | Yes | `Script.Tests` | Name of the test project to create |
| `ScriptLibraryPath` | Yes | - | Path to the script library project directory containing web resources |

> [!NOTE]
> The `ScriptLibraryPath` should point to the directory containing your web resource files (JavaScript/TypeScript files), not the `.csproj` file.

## What Gets Created

The template creates:

1. **.NET Test Project** - A .NET 8.0 project configured to run Jest tests via `dotnet test`
2. **Jest Configuration** - `jest.config.js` configured for jsdom environment
3. **Package Configuration** - `package.json` with Jest dependencies
4. **jest-core Directory** - Reusable core library containing:
   - Xrm API mocks (`setupXrm.js`)
   - Helper functions (`helpers.js`)
   - Main export (`index.js`)
5. **Tests Directory** - Sample test structure with utilities
6. **Web Resource Loader** - Utility for loading and testing web resources

## Project Structure

```
Script.Tests/
├── jest-core/
│   ├── index.js          # Main export for jest-core
│   ├── setupXrm.js       # Xrm API mock setup
│   ├── helpers.js        # Helper functions for test objects
│   └── package.json      # jest-core package definition
├── tests/
│   └── utils/
│       └── loadWebRes.js  # Web resource loader utility
├── jest.config.js        # Jest configuration
├── package.json          # Project npm dependencies
└── Script.Tests.csproj   # .NET project file
```

## Writing Tests

### Basic Test Example

Create a test file in the `tests` directory (e.g., `tests/myScript.test.js`):

```javascript
const { setupXrm, resetXrmMocks, makeForm, makeAttr, makeControl } = require('../jest-core');
const { loadWebResource } = require('./utils/loadWebRes');

describe('My Form Script', () => {
  beforeEach(() => {
    setupXrm();
  });

  afterEach(() => {
    resetXrmMocks();
  });

  test('should set field value on form load', () => {
    // Arrange
    const nameAttr = makeAttr('');
    const nameControl = makeControl();
    const formContext = makeForm(
      { name: nameAttr },
      { name: nameControl }
    );

    // Load your web resource
    const webRes = loadWebResource('path/to/your/script.js');
    
    // Act - Call your function
    webRes.onFormLoad(formContext);

    // Assert
    expect(nameAttr.setValue).toHaveBeenCalledWith('Default Value');
  });
});
```

### Testing Form Scripts

```javascript
const { setupXrm, makeForm, makeAttr, makeControl, makeExecutionContext } = require('../jest-core');

describe('Form Script Tests', () => {
  beforeEach(() => {
    setupXrm();
  });

  test('should validate required fields', () => {
    // Arrange
    const accountNameAttr = makeAttr('');
    const formContext = makeForm(
      { accountname: accountNameAttr },
      { accountname: makeControl() }
    );
    const executionContext = makeExecutionContext(formContext);

    // Act
    const isValid = yourValidationFunction(executionContext);

    // Assert
    expect(isValid).toBe(false);
    expect(formContext.ui.setFormNotification).toHaveBeenCalledWith(
      'Account name is required',
      'ERROR',
      'accountname'
    );
  });
});
```

### Testing Web API Calls

```javascript
const { setupXrm } = require('../jest-core');

describe('Web API Tests', () => {
  beforeEach(() => {
    setupXrm();
  });

  test('should create record via Web API', async () => {
    // Arrange
    const mockResponse = { id: '12345' };
    global.Xrm.WebApi.createRecord.mockResolvedValue(mockResponse);

    // Act
    const result = await yourCreateFunction('account', { name: 'Test Account' });

    // Assert
    expect(global.Xrm.WebApi.createRecord).toHaveBeenCalledWith(
      'account',
      { name: 'Test Account' }
    );
    expect(result).toEqual(mockResponse);
  });
});
```

## Jest Core API

### Setup Functions

- **`setupXrm()`** - Initializes global Xrm object with mocked API methods
- **`resetXrmMocks()`** - Resets all Xrm mock functions between tests
- **`ensureJsDom()`** - Ensures jsdom environment is available

### Helper Functions

- **`makeAttr(initialValue)`** - Creates a mock attribute with getValue/setValue methods
- **`makeLookup(value)`** - Creates a mock lookup attribute
- **`makeControl(overrides)`** - Creates a mock control with standard methods
- **`makeUI(overrides)`** - Creates a mock UI object
- **`makeForm(attrs, controls, uiOverrides)`** - Creates a mock form context
- **`makeExecutionContext(formContext)`** - Creates an execution context
- **`makeGridControl(overrides)`** - Creates a mock grid control

### Web Resource Loader

```javascript
const { loadWebResource } = require('./utils/loadWebRes');

// Load a web resource file
const webRes = loadWebResource('path/to/your/webresource.js');

// Access exported functions or global variables
webRes.yourFunction();
```

## Running Tests

### Using .NET Test SDK

```console
dotnet test
```

This will automatically run Jest tests before the .NET test phase.

### Using npm directly

```console
npm test
```

Or run Jest directly:

```console
npx jest
```

### Running specific tests

```console
npx jest tests/myScript.test.js
```

## Configuration

### Jest Configuration

The `jest.config.js` file is pre-configured with:
- `jsdom` test environment
- Test files matching pattern: `**/tests/**/*.test.js`
- Excluded paths: `node_modules` and `tests/_loadWebRes.js`

### Environment Variables

The .NET project sets these environment variables for Jest:
- `JETS_CORE` - Path to jest-core directory
- `WEBRES_PATH` - Path to script library directory (from `ScriptLibraryPath` parameter)

## Xrm API Mocks

The template provides mocks for:

- **Navigation API**: `openDialog`, `openAlertDialog`, `openErrorDialog`, `close`
- **Utility API**: `getEntityMetadata`, `showProgressIndicator`, `closeProgressIndicator`, `getGlobalContext`
- **Web API**: `createRecord`, `retrieveRecord`, `updateRecord`, `deleteRecord`, `retrieveMultipleRecords`
- **Device API**: `getBarcodeValue`, `getCurrentPosition`

All mocks are Jest mock functions, so you can use standard Jest matchers:

```javascript
expect(global.Xrm.WebApi.createRecord).toHaveBeenCalled();
expect(global.Xrm.Utility.showProgressIndicator).toHaveBeenCalledWith('Loading...');
```

## Troubleshooting

### npm packages not installed

Run the installation script manually:

```powershell
npm install
```

### Web resource not found

- Verify `ScriptLibraryPath` points to the correct directory
- Check that the path is relative to the test project directory
- Ensure the web resource file exists at the specified path

### Xrm is undefined

Make sure to call `setupXrm()` in your test's `beforeEach` hook:

```javascript
beforeEach(() => {
  setupXrm();
});
```

### Tests not running with dotnet test

- Ensure Node.js and npm are installed and available in PATH
- Verify Jest is installed: `npm list jest`
- Check that test files match the pattern in `jest.config.js`

## Related Templates

- `pp-script-library` - Create a script library project for web resources
- `pp-webresource` - Add web resources to a solution

## See Also

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [jsdom Documentation](https://github.com/jsdom/jsdom)
- [Dataverse Client-Side API](https://learn.microsoft.com/en-us/power-apps/developer/model-driven-apps/clientapi/reference)

