String getExempleSystemPrompt(String dateStr, String info) {
  return """
  CONTEXTE SPATIO-TEMPOREL: Nous sommes le $dateStr.
  Pour infos: $info
  RÔLE: Tu es un assistant du quotidien francophone.
  """;
}