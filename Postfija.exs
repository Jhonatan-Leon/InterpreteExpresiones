Code.require_file("Utilidad.exs", __DIR__)

defmodule Postfija do
  @moduledoc """
  Convierte tokens infijos a postfijos con el algoritmo de las dos pilas
  (operadores y salida)

  Mientras recorre, lleva un estado que dice qué se espera a continuación:
    - :operando: se espera un número, un booleano, un ( o un !.
    - :operador: se espera un operador binario o un ).

  Con ese estado se detectan operandos ausentes, operandos seguidos y
  paréntesis mal ubicados.
  """

  @doc """
  Convierte una lista de tokens infijos a tokens postfijos.

  Devuelve {:ok, tokens_postfijos} o {:error, posicion, motivo}.

  ## Parámetros
    - tokens: lista creada por Tokenizador.tokenizar/1, con elementos
      {tipo, valor, posicion}.

  """
  def convertir([]), do: {:error, 1, "expresión vacía"}
  def convertir(tokens), do: convertir(tokens, :operando, [], [], nil)

  @doc """
  Convierte tokens postfijos en texto, separados por espacio.

  ## Parámetros
    - tokens: lista de tokens postfijos.

  """
  def a_texto([]), do: ""
  def a_texto([t]), do: texto_token(t)
  def a_texto([t | resto]), do: texto_token(t) <> " " <> a_texto(resto)

  defp texto_token({:numero, n, _}), do: Integer.to_string(n)
  defp texto_token({:booleano, b, _}), do: Atom.to_string(b)
  defp texto_token({:operador, op, _}), do: op

  # se acabó la expresión esperando un operando: quedó incompleta (ej. "3 +")
  defp convertir([], :operando, _pila, _salida, {_tipo, valor, pos}),
    do: {:error, pos, "expresión incompleta: falta un operando después de '#{valor}'"}

  # se acabó la expresión bien: se pasan los operadores que quedaron a la salida
  defp convertir([], :operador, pila, salida, _ultimo), do: vaciar(pila, salida)


  defp convertir([{tipo, _, _} = t | resto], :operando, pila, salida, _ultimo)
       when tipo in [:numero, :booleano],
       do: convertir(resto, :operador, pila, [t | salida], t)

  # dos operandos seguidos, ej. "3 4"
  defp convertir([{tipo, valor, pos} | _], :operador, _pila, _salida, _ultimo)
       when tipo in [:numero, :booleano],
       do: {:error, pos, "falta un operador antes del operando '#{valor}'"}


  defp convertir([{:abre, _, _} = t | resto], :operando, pila, salida, _ultimo),
    do: convertir(resto, :operando, [t | pila], salida, t)

  # ej. "3 (4)"
  defp convertir([{:abre, _, pos} | _], :operador, _pila, _salida, _ultimo),
    do: {:error, pos, "falta un operador antes de '('"}

  # ")" justo después de "(", ej. "()"
  defp convertir([{:cierra, _, pos} | _], :operando, [{:abre, _, _} | _], _salida, _ultimo),
    do: {:error, pos, "paréntesis vacío"}

  # ")" cuando faltaba un operando, ej. "(3 + )"
  defp convertir([{:cierra, _, pos} | _], :operando, _pila, _salida, _ultimo),
    do: {:error, pos, "falta un operando antes de ')'"}

  # ")" normal: se sacan operadores a la salida hasta encontrar su "("
  defp convertir([{:cierra, _, pos} = t | resto], :operador, pila, salida, _ultimo) do
    case sacar_hasta_abre(pila, salida) do
      {:ok, pila, salida} -> convertir(resto, :operador, pila, salida, t)
      :error -> {:error, pos, "paréntesis de cierre sin apertura"}
    end
  end

  # es prefijo: no saca nada de la pila, solo se apila (así "!!x" funciona)
  defp convertir([{:operador, "!", _} = t | resto], :operando, pila, salida, _ultimo),
    do: convertir(resto, :operando, [t | pila], salida, t)

  # ej. "5 !"
  defp convertir([{:operador, "!", pos} | _], :operador, _pila, _salida, _ultimo),
    do: {:error, pos, "'!' solo puede ir antes de un operando"}

  # ej. "3 + * 4" o "* 4"
  defp convertir([{:operador, op, pos} | _], :operando, _pila, _salida, _ultimo),
    do: {:error, pos, "falta un operando antes de '#{op}'"}

  defp convertir([{:operador, op, _} = t | resto], :operador, pila, salida, _ultimo) do
    {pila, salida} = sacar_mayores(pila, salida, precedencia(op))
    convertir(resto, :operando, [t | pila], salida, t)
  end

  # Saca de la pila los operadores de precedencia mayor o igual a la del que
  # llega (todos los binarios asocian a la izquierda). Se detiene en un "(".
  defp sacar_mayores([{:operador, op, _} = tope | pila], salida, prec) do
    if precedencia(op) >= prec do
      sacar_mayores(pila, [tope | salida], prec)
    else
      {[tope | pila], salida}
    end
  end

  # pila vacía o con "(" arriba: no se saca nada más
  defp sacar_mayores(pila, salida, _prec), do: {pila, salida}

  # Pasa operadores a la salida hasta llegar al "(" y lo descarta
  defp sacar_hasta_abre([], _salida), do: :error
  defp sacar_hasta_abre([{:abre, _, _} | pila], salida), do: {:ok, pila, salida}
  defp sacar_hasta_abre([op | pila], salida), do: sacar_hasta_abre(pila, [op | salida])

  # Al terminar: todo lo que quedó en la pila pasa a la salida, y se invierte
  defp vaciar([], salida), do: {:ok, Utilidades.invertir(salida)}
  defp vaciar([{:abre, _, pos} | _], _salida), do: {:error, pos, "paréntesis abierto sin cerrar"}
  defp vaciar([op | pila], salida), do: vaciar(pila, [op | salida])

  # Mayor número = se calcula primero
  defp precedencia("!"), do: 7
  defp precedencia(op) when op in ["*", "/"], do: 6
  defp precedencia(op) when op in ["+", "-"], do: 5
  defp precedencia(op) when op in ["<", "<=", ">", ">="], do: 4
  defp precedencia(op) when op in ["==", "!="], do: 3
  defp precedencia("&&"), do: 2
  defp precedencia("||"), do: 1
end
