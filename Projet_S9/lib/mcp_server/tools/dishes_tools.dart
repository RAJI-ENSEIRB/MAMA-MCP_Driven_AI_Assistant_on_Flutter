import 'package:mcp_dart/mcp_dart.dart';
import 'dart:convert';
import 'repositories/dishes_repository.dart';

class NwsResult<T> {
  final T? data;
  final String? error;
  NwsResult({this.data, this.error});
  bool get isSuccess => error == null;

  Map<String, dynamic> toJson() {
    return {'success': isSuccess, 'data': data, 'error': error};
  }
}

class DishesTools {
  final InMemoryDishesRepository _repository = InMemoryDishesRepository();

  Future<void> register(McpServer server) async {
    await _repository.init();
    
    server.registerTool(
      'get_menu',
      description:'''Retrieves the list of dishes the user ate on a specific date''',
      inputSchema: ToolInputSchema(
        properties: {
          'date': JsonSchema.string(
            pattern: r'^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-\d{4}$',
            description: "Date au format JJ-MM-AAAA",
          )
        },
        required: ['date'],
      ),
      callback: (args, extra) async {
        final date = args["date"]?.toString().trim().toLowerCase() ?? '';

        try {
          final filtered = await _repository.getDishes(date);
          final result = NwsResult(data: filtered);
          return CallToolResult(
            content: [TextContent(text: jsonEncode(result.toJson()))]
          );

        } catch (error) {
          return CallToolResult(
            content: [TextContent(text: "Error reading dishes data: $error")],
            isError: true,
          );
        }
      },
    );

    server.registerTool(
      "add_dish",
      description: '''Add a new food item or meal consumed by the user on a given day''',
      inputSchema: ToolInputSchema(
        properties: {
          'name': JsonSchema.string(pattern: r'^[a-zA-Z\sàâäéèêëïîôöùûüç\-]+$'),
          'date': JsonSchema.string(
            pattern: r'^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-\d{4}$',
            description: "Date au format JJ-MM-AAAA"
          ),
          'meal': JsonSchema.string(enumValues: ['breakfast', 'lunch', 'dinner', 'snack']),
          'quantity': JsonSchema.string(pattern: r'^[a-zA-Z0-9\sàâäéèêëïîôöùûüç\-]+$', defaultValue: '1')
        },
        required: ['name', 'date'],
      ),
      callback: (args, extra) async {
        final name = args["name"]?.toString().trim().toLowerCase() ?? '';
        final date = args["date"]?.toString().trim().toLowerCase() ?? '';
        final meal = args["meal"]?.toString().trim().toLowerCase() ?? 'unknown';
        final quantity = args["quantity"]?.toString().trim().toLowerCase() ?? '1';

        try {
          final addedDish = await _repository.addDish(name, date, meal, quantity);
          final result = NwsResult(data: addedDish);
          return CallToolResult(content: [
              TextContent(text: "Dish added: ${result.data!['quantity']} ${result.data!['name']} for ${result.data!['date']} (${result.data!['meal']})",
              ),
            ],
          );

        } catch (error) {
          return CallToolResult(
            content: [TextContent(text: "Error adding dish: $error")],
            isError: true,
          );
        }
      }
    );

    server.registerTool(
      "del_dish",
      description: '''Removes a specific meal entry from the user's history on a given day''',
      inputSchema: ToolInputSchema(
        properties: {
          'id': JsonSchema.integer(description: 'ID of the dish to delete'),
        },
        required: ['id'],
      ),
      callback: (args, extra) async {
        final id = args["id"] as int?;

        if (id == null) {
          return CallToolResult(
            content: [TextContent(text: "Missing required parameter: 'id'")],
            isError: true,
          );
        }

        final success = _repository.deleteDishById(id);
        if (!success) {
          return CallToolResult(
            content: [TextContent(text: "Dish with id $id not found.")],
            isError: true,
          );
        }

        return CallToolResult(
          content: [TextContent(text: "Deleted dish $id successfully")],
        );
      },
    );

    server.registerTool(
      "edit_dish",
      description: '''Updates details of an existing meal entry in the user's history''',
      inputSchema: ToolInputSchema(
        properties: {
          'id': JsonSchema.integer(description: 'ID of the dish to edit'),
          'newName': JsonSchema.string(pattern: r'^[a-zA-Z\sàâäéèêëïîôöùûüç\-]+$'),
          'newDate': JsonSchema.string(
            pattern: r'^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-\d{4}$',
            description: "Date au format JJ-MM-AAAA",
          ),
          'newMeal': JsonSchema.string(enumValues: ['breakfast', 'lunch', 'dinner', 'snack']),
          'newQuantity': JsonSchema.string(pattern: r'^[a-zA-Z0-9\sàâäéèêëïîôöùûüç\-]+$')
        },
        required: ['id'],
      ),
      callback: (args, extra) async {
        final id = args["id"] as int?;
        final newName = args["newName"]?.toString().trim().toLowerCase();
        final newDate = args["newDate"]?.toString().trim().toLowerCase();
        final newMeal = args["newMeal"]?.toString().trim().toLowerCase();
        final newQuantity = args["newQuantity"]?.toString().trim().toLowerCase();

        if (id == null) {
          return CallToolResult(
            content: [TextContent(text: "Missing required parameter: 'id'")],
            isError: true,
          );
        }

        if (newName == null &&
            newDate == null &&
            newMeal == null &&
            newQuantity == null) {
          return CallToolResult(
            content: [
              TextContent(
                text:
                    "Nothing to update. Pass at least one of: name, date, meal, quantity",
              ),
            ],
            isError: true,
          );
        }

        final dish = _repository.getDishById(id);
        if (dish == null) {
          return CallToolResult(
            content: [TextContent(text: "Dish with id $id not found.")],
            isError: true,
          );
        }

        final updates = <String, dynamic>{};
        if (newName != null) updates["name"] = newName;
        if (newDate != null) updates["date"] = newDate;
        if (newMeal != null) updates["meal"] = newMeal;
        if (newQuantity != null) updates["quantity"] = newQuantity;

        final updated = _repository.updateDishById(id, updates);
        if (!updated) {
          return CallToolResult(
            content: [TextContent(text: "Failed to update dish $id.")],
            isError: true,
          );
        }
        return CallToolResult(
          content: [TextContent(text: "Dish $id updated successfully.")],
        );
      },
    );

    server.registerTool(
      "reset_dishes",
      description: "Clears all recorded meal data",
      callback: (args, extra) async {
        await _repository.resetAllDishes();
        return CallToolResult(
          content: [TextContent(text: "All dishes have been reset")],
        );
      },
    );
  }
}