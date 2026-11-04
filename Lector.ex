defmodule Lector do
  # aca es casi igual al lector de itinerarios pero con una diferencia importante: al final NO hay Enum,
  # porque el Enum es el que ejecuta todo y lo vuelve lista. Aca se devuelve el stream sin ejecutar
  # para que cada expresion se lea y se procese de una en una cuando alguien lo recorra
  def leer_expresiones(ruta) do
    if File.exists?(ruta) do
      stream = ruta
      |> File.stream!() #procede a leer linea por linea
      |> Stream.with_index(1) # Los enumera, se hace antes de filtrar para no perder el numero real de la linea
      |> Stream.map(fn {texto, num} -> {num, String.trim(texto)} end) # le pone el numero adelante y limpia los espacios y el salto de linea
      |> Stream.reject(fn {_num, texto} -> ignorar?(texto) end) #quita vacios y comentarios

      {:ok, stream} # aqui todavia no se ha leido nada, solo esta la "receta" de como leer
    else
      {:error, "no se encontro el archivo requerido: #{ruta}"} # avisa cual falta y no revienta
    end
  end

  defp ignorar?(""), do: true #ignora los vacios
  defp ignorar?("#" <> _), do: true # ignora los comentarios
  defp ignorar?(_), do: false # deja pasar todo lo demas
end
