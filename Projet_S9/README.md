# Notices pour les développeurs

## Pour que ça marche:

### Sur https://aistudio.google.com/app/projects :

Crée des projets (10 max). Chaque projet à un quota de 20 utilisations par models et par jour, donc max 400/jour.

### Sur https://aistudio.google.com/app/api-keys :
Pour chaque projet, crée 1 clé api. (Attention: 2 clés reliées au même projet consomment sur le même quota. Il faut que les clés soient sur des projets différents)

### Dans `.env`:
Ajoute tes clés api gemini et les 2 models
```env
API_KEY_1=AIzaSy...
API_KEY_2=AIzaSy...
API_KEY_3=AIzaSy...
...
MODEL_1=gemini-2.5-flash
MODEL_2=gemini-2.5-flash-lite
```
## Pour ajouter un tool:

### Dans 'lib/mcp_server/mcp_server.dart':

Ajoute dans createMcpServer() le tool avec la structure suivante:

```dart
  server.registerTool(
    "exemple_tool_name",
    description: '''Modifies an existing entry's infos''',
    // Add args type and description here (no args => no inputSchema)
    inputSchema: ToolInputSchema(
      properties: {
        'id': JsonSchema.integer(
          description: "ID of the entry to edit"
        ),
        'date': JsonSchema.string(
          pattern: r'^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-\d{4}$',
          description: "Date au format JJ-MM-AAAA",
        ),
        'meal': JsonSchema.string(
          enumValues: ['breakfast', 'lunch', 'dinner', 'snack']
        ),
        "quality": JsonSchema.integer(
          minimum: 0, maximum: 5, description: "Quality 0-5"
        ),
        'temp': JsonSchema.number(
          minimum: -20, maximum: 100, description: 'Temperature in the room'
        ),
        "note": JsonSchema.string(
          description: "Reason why edit (optional)"
        )
      },
      // Mandatory args
      required: ['id', 'date'],
    ),
    callback: ({args, extra}) async {
      // Recup args
      final idRaw = args?["id"]?.toString().trim() ?? '';
      final id = int.tryParse(idRaw);
      final newDate = args?["date"]?.toString().trim();

      try {
        // ...
      
        // Return result
        return CallToolResult.fromContent(
          content: [TextContent(text: "Entry $id updated successfully")],
        );

      } catch (error) {
        return CallToolResult(
            content: [TextContent(text: "Error reading dishes data: $error")],
            isError: true,
          );
      }
    },
  );
```

## Pour ajouter un promptSystem:

Crée un fichier exemple_prompt.dart dans 'lib/mcp_client/prompts' contenant:
```dart
String getExempleSystemPrompt() {
  return """
  TON SYSTEM PROMPT
  """
}
```

### Dans 'lib/app_state.dart':

Ajoute son nom à la liste:
```dart
final List<String> promptNames = [
    "general",
    "smart",
    "exemple",
  ]; // List of all prompts
```

### Dans 'lib/mcp_client/mcp_client.dart':

Importe le prompt:
```dart
import 'mcp_client/prompts/exemple_prompt.dart';
```

Ajoute un case dans le switch-case de getSystemPrompt():
```dart
  Future<String> getSystemPrompt(String clientName) async {
    switch (clientName) {
      case "general":
        return getGeneralSystemPrompt(getDateTime());
      case "smart":
        return getSmartSystemPrompt(getDateTime());
      case "exemple":
        return getExempleSystemPrompt();
      default:
        throw Exception("Unknown client type: $clientName");
    }
  }
```
### Pour un prompt dynamique:

Comme dans l'exemple ci-dessous, tu peux injecter dynamiquement des valeurs dans le promptSystem comme la date ou récupérer en avance des infos depuis le server.
```dart
String getExempleSystemPrompt(String dateStr, String info) {
  return """
  CONTEXTE SPATIO-TEMPOREL: Nous sommes le $dateStr.
  Pour infos: $info
  RÔLE: Tu es un assistant du quotidien francophone.
  """;
}
```

Pour passer en argument des infos depuis le serveur, modifie le switch-case de getSystemPrompt dans mcp_client.dart:
```dart
case "exemple":
  try {
    String info = await _bridge.callTool('get_weather', {'location': 'Paris'});
    return getExempleSystemPrompt(getDateTime(), info);
  } catch (e) {
    return getExempleSystemPrompt(getDateTime(), "Error: $e");
  }
```

