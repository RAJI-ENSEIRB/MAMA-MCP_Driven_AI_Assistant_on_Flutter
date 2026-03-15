import 'package:mcp_dart/mcp_dart.dart';
import 'dart:convert';
import 'repositories/weather_repository.dart';

class WeatherTools {
  final WeatherRepository _repository = WeatherRepository();

  void register(McpServer server) {
    server.registerTool(
      'get_weather',
      description:
          'Météo actuelle en France. Utiliser quand on demande la météo pour une ville, un code postal ou des coordonnées'
          'Merci de toujours preciser la date d\'aujourd\'hui lors de la réponse. Ex: "aujourd\'hui" => 5 nov si aujourd\'hui 5 nov'
          '''Peut aider à la prise de décision comme des questions "Puis-je courir aujourd'hui ?" "Faut-il contacter ma mère aujourd'hui ?", etc. 
          L'agent peut interpréter la météo et répondre de manière naturelle''',
      inputSchema: ToolInputSchema(
        properties: {
          'city': JsonSchema.string(description: 'Nom de la ville'),
          'postalCode': JsonSchema.string(pattern: r'^\d{5}$', description: 'Code postal'),
          'lat': JsonSchema.number(minimum: -90, maximum: 90, description: 'Latitude'),
          'lon': JsonSchema.number(minimum: -180, maximum: 180, description: 'Longitude'),
        },
      ),
      callback: (args, extra) async {
        try {
          final city = (args['city'] as String?)?.trim();
          final postal = (args['postalCode'] as String?)?.trim();
          final lat = (args['lat'] as num?)?.toDouble();
          final lon = (args['lon'] as num?)?.toDouble();

          final loc = await _repository.fetchLatLonFrance(
            city: (city?.isEmpty ?? true) ? null : city,
            postalCode: (postal?.isEmpty ?? true) ? null : postal,
            lat: lat,
            lon: lon,
          );

          final fw = await _repository.fetchWeather(
            loc['lat'] as double,
            loc['lon'] as double,
          );
          final cw = fw['current_weather'] as Map<String, dynamic>;

          final result = {
            'location': {
              'name': loc['name'],
              'country_code': loc['country_code'],
              'lat': loc['lat'],
              'lon': loc['lon'],
            },
            'current': {
              'temperature_c': cw['temperature'],
              'windspeed_kmh': cw['windspeed'],
              'weathercode': cw['weathercode'],
              'time': cw['time'],
            },
          };

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_weather: $e')],
            isError: true,
          );
        }
      }
    );

    server.registerTool(
      'get_weather_context',
      description:
          'Contexte météo pour une ACTIVITÉ EXTÉRIEURE en France. '
          'Toujours utiliser ce tool pour les questions de type : '
          '"je veux courir demain", "je veux faire du yoga dans un parc", '
          '"je veux danser du hip-hop sur la pelouse", "je vais me promener en forêt", '
          '"pique-nique", "sport dehors", "parc", "pelouse", "forêt", "terrain". '
          'Le tool renvoie la météo quotidienne de la date cible (daysAhead) '
          'ET les 3 jours juste avant cette date, avec pour chaque jour température et pluie, '
          'et une indication de source ("observed" ou "forecast"). '
          'L’agent doit ensuite interpréter lui-même ces données pour juger si le sol/les conditions sont adaptés',
      inputSchema: ToolInputSchema(
        properties: {
          'city': JsonSchema.string(description: 'Nom de la ville'),
          'postalCode': JsonSchema.string(pattern: r'^\d{5}$', description: 'Code postal'),
          'lat': JsonSchema.number(minimum: -90, maximum: 90, description: 'Latitude'),
          'lon': JsonSchema.number(minimum: -180, maximum: 180, description: 'Longitude'),
          'daysAhead': JsonSchema.integer(minimum: 0, maximum: 15,
            description: "Nombre de jours à l'avance (0=aujourd'hui, max 15)",
          ),
        },
        required: ['daysAhead'],
      ),
      callback: (args, extra) async {
        try {
          final day = args['daysAhead'] as int;
          final city = (args['city'] as String?)?.trim();
          final postal = (args['postalCode'] as String?)?.trim();
          final lat = (args['lat'] as num?)?.toDouble();
          final lon = (args['lon'] as num?)?.toDouble();
          final loc = await _repository.fetchLatLonFrance(
            city: (city?.isEmpty ?? true) ? null : city,
            postalCode: (postal?.isEmpty ?? true) ? null : postal,
            lat: lat, lon: lon,
          );

          final double latVal = loc['lat'] as double;
          final double lonVal = loc['lon'] as double;

          //Calcul des dates cible + 3j précédents
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final targetDate = today.add(Duration(days: day));
          final prevDates = <DateTime>[
            targetDate.subtract(const Duration(days: 1)),
            targetDate.subtract(const Duration(days: 2)),
            targetDate.subtract(const Duration(days: 3)),
          ];

          final targetDateStr = _repository.formatDate(targetDate);

          final forecastData = await _repository.fetchDailyForecast(
            latVal,
            lonVal,
            day + 1,
          ); //car on commence à 0 qui est aujourd'hui
          final fDaily = forecastData['daily'] as Map<String, dynamic>;
          final List<String> fTimes = (fDaily['time'] as List)
              .map((e) => e.toString())
              .toList();
          final List<double> fTMax = (fDaily['temperature_2m_max'] as List)
              .map((e) => (e as num).toDouble())
              .toList();
          final List<double> fTMin = (fDaily['temperature_2m_min'] as List)
              .map((e) => (e as num).toDouble())
              .toList();
          final List<double> fRain = (fDaily['precipitation_sum'] as List)
              .map((e) => (e as num).toDouble())
              .toList();

          final int idxTarget = fTimes.indexOf(targetDateStr);
          if (idxTarget == -1) {
            throw Exception(
              'Date cible $targetDateStr introuvable dans les prévisions',
            );
          }
          final target = {
            'date': targetDateStr,
            'temperature_max_c': fTMax[idxTarget],
            'temperature_min_c': fTMin[idxTarget],
            'precipitation_sum_mm': fRain[idxTarget],
          };

          //Si jours < aujourd'hui => à récupérer via "past" (observed)
          //Si jours >= aujourd'hui => via "forecast" (forecast)
          final Map<String, Map<String, dynamic>> previousDays = {};
          final List<DateTime> needPast = [];
          final List<DateTime> needForecast = [];

          for (final d in prevDates) {
            if (d.isBefore(today)) {
              needPast.add(d);
            } else {
              needForecast.add(d);
            }
          }

          for (final d in needForecast) {
            final ds = _repository.formatDate(d);
            final idx = fTimes.indexOf(ds);
            if (idx == -1) {
              continue;
            }
            previousDays[ds] = {
              'date': ds,
              'temperature_max_c': fTMax[idx],
              'temperature_min_c': fTMin[idx],
              'precipitation_sum_mm': fRain[idx],
              'source': 'forecast',
            };
          }

          if (needPast.isNotEmpty) {
            final pastData = await _repository.fetchPastWeather(latVal, lonVal, 3);
            final pDaily = pastData['daily'] as Map<String, dynamic>;
            final List<String> pTimes = (pDaily['time'] as List)
                .map((e) => e.toString())
                .toList();
            final List<double> pTMax = (pDaily['temperature_2m_max'] as List)
                .map((e) => (e as num).toDouble())
                .toList();
            final List<double> pTMin = (pDaily['temperature_2m_min'] as List)
                .map((e) => (e as num).toDouble())
                .toList();
            final List<double> pRain = (pDaily['precipitation_sum'] as List)
                .map((e) => (e as num).toDouble())
                .toList();

            for (final d in needPast) {
              final ds = _repository.formatDate(d);
              final idx = pTimes.indexOf(ds);
              if (idx == -1) {
                continue;
              }
              previousDays[ds] = {
                'date': ds,
                'temperature_max_c': pTMax[idx],
                'temperature_min_c': pTMin[idx],
                'precipitation_sum_mm': pRain[idx],
                'source': 'observed',
              };
            }
          }

          final prevList = <Map<String, dynamic>>[];
          for (final d in prevDates.reversed) {
            final ds = _repository.formatDate(d);
            if (previousDays.containsKey(ds)) {
              prevList.add(previousDays[ds]!);
            }
          }

          final result = {
            'location': {
              'name': loc['name'],
              'country_code': loc['country_code'],
              'lat': latVal,
              'lon': lonVal,
            },
            'target': {'days_ahead': day, ...target},
            'previous_3_days': prevList,
          };

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_weather_context: $e')],
            isError: true,
          );
        }
      },
    );

    server.registerTool(
      'get_weather_forecast',
      description:'''
        Prévisions météo simples en France pour un jour futur. Utiliser quand on demande "demain" (daysAhead=1), "après-demain" (daysAhead=2) ou "dans 5 jours" (daysAhead=5).
        OBLIGATOIRE : Vous devez fournir soit "city", soit "postalCode", soit le couple "lat"/"lon".
        IMPORTANT : Si l'utilisateur ne précise pas la localisation, utilise d'abord l'outil 'get_current_location'.
        TOUJOURS preciser la date en question lors de la réponse. Ex: "demain" => 6 nov si aujourd'hui 5 nov
        Peut aider à la prise de décision mais pour des questions directes "Quel temps fera-t-il à Paris demain ?" "Faut-il contacter ma mère demain ?", etc.
        Ne pas utiliser ce tool pour la météo d'aujours'hui, utiliser "get_weather" pour la météo d'aujourd'hui
        Ne pas utiliser ce tool pour des activités extérieures (course, yoga, parc, forêt...), utiliser "get_weather_context" pour avoir le contexte météo des jours précédents.
      ''',
      inputSchema: ToolInputSchema(
        properties: {
          'city': JsonSchema.string(description: 'Nom de la ville'),
          'postalCode': JsonSchema.string(pattern: r'^\d{5}$', description: 'Code postal'),
          'lat': JsonSchema.number(minimum: -90, maximum: 90, description: 'Latitude'),
          'lon': JsonSchema.number(minimum: -180, maximum: 180, description: 'Longitude'),
          'daysAhead': JsonSchema.integer(minimum: 0, maximum: 15,
            description: "Nombre de jours dans le futur (1=demain)",
          ),
        },
        required: ['daysAhead'],
      ),
      callback: (args, extra) async {
        try {
          final daysAhead = args['daysAhead'] as int;
          final city = (args['city'] as String?)?.trim();
          final postal = (args['postalCode'] as String?)?.trim();
          final lat = (args['lat'] as num?)?.toDouble();
          final lon = (args['lon'] as num?)?.toDouble();

          final loc = await _repository.fetchLatLonFrance(
            city: (city?.isEmpty ?? true) ? null : city,
            postalCode: (postal?.isEmpty ?? true) ? null : postal,
            lat: lat,
            lon: lon,
          );

          final data = await _repository.fetchDailyForecast(
            loc['lat'] as double,
            loc['lon'] as double,
            daysAhead + 1,
          ); //car on commence à 0 qui est aujourd'hui

          final daily = data['daily'] as Map<String, dynamic>;
          final date = _repository.getDailyValue(daily, 'time', daysAhead);
          final tMax = _repository.getDailyValue(daily, 'temperature_2m_max', daysAhead);
          final tMin = _repository.getDailyValue(daily, 'temperature_2m_min', daysAhead);
          final rain = _repository.getDailyValue(daily, 'precipitation_sum', daysAhead);

          final result = {
            'location': {
              'name': loc['name'],
              'country_code': loc['country_code'],
              'lat': loc['lat'],
              'lon': loc['lon'],
            },
            'forecast': {
              'date': date,
              'temperature_max_c': tMax,
              'temperature_min_c': tMin,
              'precipitation_sum_mm': rain,
            },
          };

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_weather_forecast: $e')],
            isError: true,
          );
        }
      },
    );

    server.registerTool(
      'get_past_weather',
      description: '''
        Météo en France pour un jour passé. Utiliser quand on demande "hier" (daysAgo=1), "avant-hier" (daysAgo=2) ou "il y 5 jours" (daysAgo=5).
        OBLIGATOIRE : Vous devez fournir soit "city", soit "postalCode", soit le couple "lat"/"lon".
        IMPORTANT : Si l'utilisateur ne précise pas la localisation, utilise d'abord l'outil 'get_current_location'.
        TOUJOURS preciser la date en question lors de la réponse. Ex: "hier" => 4 nov si aujourd'hui 5 nov
        Peut aider à la prise de décision comme des questions "J'ai oublié mon linge dehors hier, est ce grave ?" "Faut-il contacter ma mère par rapport au temps d'hier ?", etc. 
      ''',
      inputSchema: ToolInputSchema(
        properties: {
          'city': JsonSchema.string(description: 'Nom de la ville'),
          'postalCode': JsonSchema.string(pattern: r'^\d{5}$', description: 'Code postal'),
          'lat': JsonSchema.number(minimum: -90, maximum: 90, description: 'Latitude'),
          'lon': JsonSchema.number(minimum: -180, maximum: 180, description: 'Longitude'),
          'daysAgo': JsonSchema.integer(minimum: 1, maximum: 15,
            description: "Nombre de jours dans le passé (1=hier, 2=avant-hier)",
          ),
        },
        required: ['daysAgo'],
      ),
      callback: (args, extra) async {
        try {
          final daysAgo = args['daysAgo'] as int;
          final city = (args['city'] as String?)?.trim();
          final postal = (args['postalCode'] as String?)?.trim();
          final lat = (args['lat'] as num?)?.toDouble();
          final lon = (args['lon'] as num?)?.toDouble();

          final loc = await _repository.fetchLatLonFrance(
            city: (city?.isEmpty ?? true) ? null : city,
            postalCode: (postal?.isEmpty ?? true) ? null : postal,
            lat: lat,
            lon: lon,
          );

          final data = await _repository.fetchPastWeather(
            loc['lat'] as double,
            loc['lon'] as double,
            daysAgo,
          );

          final daily = data['daily'] as Map<String, dynamic>;

          final date = _repository.getDailyValue(daily, 'time', 0); //voir url (past_days + 6 jours) ou README
          final tMax = _repository.getDailyValue(daily, 'temperature_2m_max', 0);
          final tMin = _repository.getDailyValue(daily, 'temperature_2m_min', 0);
          final rain = _repository.getDailyValue(daily, 'precipitation_sum', 0);

          final result = {
            'location': {
              'name': loc['name'],
              'country_code': loc['country_code'],
              'lat': loc['lat'],
              'lon': loc['lon'],
            },
            'past': {
              'date': date,
              'temperature_max_c': tMax,
              'temperature_min_c': tMin,
              'precipitation_sum_mm': rain,
            },
          };

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_past_weather: $e')],
            isError: true,
          );
        }
      }
    );
  }
}