defmodule GreenWorker.Util do
  @moduledoc false

  def get_mandatory_field(keywords, field_name) when is_list(keywords),
    do: keywords[field_name] || missing_field(field_name)

  def missing_field(field_name), do: raise("'#{field_name}' field is mandatory")

  def get_optional_field(keywords, field_name, default \\ nil) when is_list(keywords),
    do: keywords[field_name] || default
end
