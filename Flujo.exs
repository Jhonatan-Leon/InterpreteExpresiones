# Integrantes:
# - Ruben Steven Sanchez
# - Jhonatan Cardona
# - Diana Valencia

Code.require_file("Lector.ex", __DIR__)
Code.require_file("Interprete.exs", __DIR__)

defmodule Flujo do
  @moduledoc """
  Problema 3: une la lectura perezosa, el intérprete y la escritura de salidas.

  Flujo de datos, una expresión a la vez:

      Lector.leer_expresiones/1     (Stream de {linea_fisica, texto})
        - Stream.map(Interprete.procesar/1)
        - Enum.reduce que escribe cada fila apenas se produce

  El Stream no se ejecuta hasta el `Enum.reduce`, así que nunca se guardan
  todas las expresiones en memoria. Las salidas se crean o reemplazan en cada
  ejecución y se escriben línea por línea.

  Salidas:
  - resultado_expresiones.csv  (linea;infija;postfija;resultado;estado)
  - errores_expresiones.txt    (línea física, expresión original y motivo)
  """

  @entrada Path.join([__DIR__, "datos", "expresiones.txt"])
  @salida_csv Path.join(__DIR__, "resultado_expresiones.csv")
  @salida_errores Path.join(__DIR__, "errores_expresiones.txt")
  @encabezado "linea;infija;postfija;resultado;estado\n"

  @doc """
  Procesa el archivo de expresiones y muestra en pantalla cuántas se evaluaron
  correctamente y cuántas tuvieron error.

  Devuelve `{:ok, {correctas, con_error}}` o `{:error, motivo}` (por ejemplo,
  si falta el archivo de entrada), sin lanzar excepciones.

  ## Parámetros
    - ruta_entrada: ruta de expresiones.txt (por defecto, junto a este archivo).

  """
  def ejecutar(ruta_entrada \\ @entrada) do
    with {:ok, expresiones} <- Lector.leer_expresiones(ruta_entrada),
         {:ok, csv} <- abrir(@salida_csv),
         {:ok, errores} <- abrir(@salida_errores) do
      IO.write(csv, @encabezado)

      {correctas, con_error} =
        expresiones
        |> Stream.map(&evaluar_linea/1)
        |> Enum.reduce({0, 0}, fn resultado, contadores ->
          registrar(resultado, contadores, csv, errores)
        end)

      File.close(csv)
      File.close(errores)

      mostrar_resumen(correctas, con_error)
      {:ok, {correctas, con_error}}
    else
      {:error, motivo} ->
        IO.puts(:standard_error, "No se pudo completar el proceso: #{motivo}")
        {:error, motivo}
    end
  end

  # Crea o reemplaza un archivo de salida. Un error se devuelve como tupla.
  defp abrir(ruta) do
    case File.open(ruta, [:write, :utf8]) do
      {:ok, archivo} -> {:ok, archivo}
      {:error, razon} -> {:error, "no se pudo crear #{ruta}: #{:file.format_error(razon)}"}
    end
  end

  # Paso perezoso: conserva la línea física y el texto original junto al resultado.
  defp evaluar_linea({numero, texto} = entrada) do
    {numero, texto, Interprete.procesar(entrada)}
  end

  # Expresión correcta: una fila OK en el CSV.
  defp registrar({numero, texto, {:ok, postfija, valor}}, {correctas, con_error}, csv, _errores) do
    IO.write(csv, fila(numero, texto, postfija, valor, "OK"))
    {correctas + 1, con_error}
  end

  # Expresión con error: fila ERROR en el CSV (el motivo va en `resultado`)
  # y una línea en errores_expresiones.txt.
  defp registrar(
         {numero, texto, {:error, postfija, motivo}},
         {correctas, con_error},
         csv,
         errores
       ) do
    IO.write(csv, fila(numero, texto, postfija, motivo, "ERROR"))
    IO.write(errores, "Línea #{numero}: #{texto} -> #{motivo}\n")
    {correctas, con_error + 1}
  end

  defp fila(numero, infija, postfija, resultado, estado) do
    "#{numero};#{campo(infija)};#{postfija};#{campo(resultado)};#{estado}\n"
  end

  # El separador del CSV es ";". Si un texto lo trae (por ejemplo, un motivo
  # como "caracter no permitido: ';'"), el campo se encierra entre comillas
  # para no romper las columnas.
  defp campo(texto) do
    if String.contains?(texto, [";", "\"", "\n"]) do
      "\"" <> String.replace(texto, "\"", "\"\"") <> "\""
    else
      texto
    end
  end

  defp mostrar_resumen(correctas, con_error) do
    IO.puts("Expresiones evaluadas correctamente: #{correctas}")
    IO.puts("Expresiones con error: #{con_error}")
    IO.puts("Detalle en #{Path.basename(@salida_csv)} y #{Path.basename(@salida_errores)}")
  end
end

case System.argv() do
  [ruta | _] -> Flujo.ejecutar(ruta)
  [] -> Flujo.ejecutar()
end
