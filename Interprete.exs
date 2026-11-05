Code.require_file("Entrada.ex", __DIR__)
Code.require_file("Postfija.exs", __DIR__)
Code.require_file("Evaluador.exs", __DIR__)

defmodule Interprete do
  @moduledoc """
  Intérprete de expresiones infijas: genera la notación postfija y calcula
  el resultado.

  ## Qué acepta
    - Enteros no negativos (0, 1, 25) y los literales true y false.
    - Paréntesis y los operadores ! * / + - < <= > >= == != && ||.

  ## Qué NO acepta
    - Signo negativo unario (-3).
    - Números decimales en la entrada (el resultado de / sí puede serlo).
    - Variables.
    - Evaluación con cortocircuito: && y || siempre evalúan ambos lados.

  ## Reglas de tipos
    - + - * / y < <= > >= requieren números.
    - ! && || requieren booleanos.
    - == y != requieren dos valores del mismo tipo.
    - Dividir por cero es un error.
  """

  @doc """
  Procesa una línea: valida, tokeniza, convierte a postfija y evalúa.

  Devuelve {:ok, postfija, resultado} o {:error, postfija, motivo}.
  La postfija es "" si no se pudo generar (error de validación,
  tokenizado o estructura). Los motivos de esas etapas incluyen la posición
  del error, contada en caracteres.

  ## Parámetros
    - entrada: tupla {linea, texto} como la que entrega el stream de
      Lector.leer_expresiones/1.

  """
  def procesar({_linea, _texto} = entrada) do
    case Entrada.preparar(entrada) do
      {:ok, tokens} -> convertir_y_evaluar(tokens)
      {:error, pos, motivo} -> {:error, "", "posición #{pos}: #{motivo}"}
    end
  end

  # primero la postfija y, si existe, se evalúa
  defp convertir_y_evaluar(tokens) do
    case Postfija.convertir(tokens) do
      {:error, pos, motivo} ->
        {:error, "", "posición #{pos}: #{motivo}"}

      {:ok, postfija} ->
        texto = Postfija.a_texto(postfija)

        case Evaluador.evaluar(postfija) do
          {:ok, valor} -> {:ok, texto, Evaluador.formatear(valor)}
          {:error, motivo} -> {:error, texto, motivo}
        end
    end
  end
end
