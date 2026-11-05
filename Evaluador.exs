defmodule Evaluador do
  @moduledoc """
  Evalúa tokens postfijos recursivamente con una pila de valores tipados.

  Los valores llevan su tipo: {:num, n} y {:bool, b}. Así se puede
  comprobar que cada operador reciba los tipos que exige.
  """

  @doc """
  Evalúa una lista de tokens postfijos.

  Devuelve {:ok, valor} o {:error, motivo}.

  ## Parámetros
    - tokens: lista de tokens postfijos creada por Postfija.convertir/1.

  """
  def evaluar(tokens), do: evaluar(tokens, [])

  @doc """
  Convierte un valor tipado en el texto que va en el campo resultado.

  Un número decimal con parte entera exacta se muestra sin decimales
  (5.0 queda 5).

  ## Parámetros
    - valor: {:num, n} o {:bool, b}.

  """
  def formatear({:bool, b}), do: Atom.to_string(b)
  def formatear({:num, n}) when is_integer(n), do: Integer.to_string(n)

  def formatear({:num, n}) do
    if n == trunc(n), do: Integer.to_string(trunc(n)), else: Float.to_string(n)
  end

  # sin tokens, debe quedar exactamente un valor en la pila
  defp evaluar([], [valor]), do: {:ok, valor}
  defp evaluar([], []), do: {:error, "la expresión no produce ningún valor"}
  defp evaluar([], _pila), do: {:error, "sobran operandos en la expresión"}

  # Un operando se apila con su tipo
  defp evaluar([{:numero, n, _} | resto], pila), do: evaluar(resto, [{:num, n} | pila])
  defp evaluar([{:booleano, b, _} | resto], pila), do: evaluar(resto, [{:bool, b} | pila])

  # "!" saca un valor, que debe ser booleano
  defp evaluar([{:operador, "!", _} | resto], [{:bool, b} | pila]),
    do: evaluar(resto, [{:bool, not b} | pila])

  defp evaluar([{:operador, "!", _} | _], [valor | _]),
    do: {:error, "el operador '!' requiere un booleano, pero recibió #{tipo(valor)}"}

  defp evaluar([{:operador, "!", _} | _], []),
    do: {:error, "falta un operando para '!'"}

  # la pila tiene [derecho, izquierdo | resto]
  defp evaluar([{:operador, op, _} | resto], [der, izq | pila]) do
    case aplicar(op, izq, der) do
      {:ok, valor} -> evaluar(resto, [valor | pila])
      {:error, motivo} -> {:error, motivo}
    end
  end

  defp evaluar([{:operador, op, _} | _], _pila),
    do: {:error, "falta un operando para '#{op}'"}

  defp aplicar("+", {:num, a}, {:num, b}), do: operacion_numerica("+", a, b)
  defp aplicar("-", {:num, a}, {:num, b}), do: operacion_numerica("-", a, b)
  defp aplicar("*", {:num, a}, {:num, b}), do: operacion_numerica("*", a, b)

  # "when b == 0" y no el patrón 0, porque 0.0 también es cero
  defp aplicar("/", {:num, _}, {:num, b}) when b == 0, do: {:error, "división por cero"}
  defp aplicar("/", {:num, a}, {:num, b}), do: operacion_numerica("/", a, b)

  defp aplicar("<", {:num, a}, {:num, b}), do: {:ok, {:bool, a < b}}
  defp aplicar("<=", {:num, a}, {:num, b}), do: {:ok, {:bool, a <= b}}
  defp aplicar(">", {:num, a}, {:num, b}), do: {:ok, {:bool, a > b}}
  defp aplicar(">=", {:num, a}, {:num, b}), do: {:ok, {:bool, a >= b}}

  # "t" repetido en el patrón obliga a que los dos valores tengan el mismo tipo
  defp aplicar("==", {t, a}, {t, b}), do: {:ok, {:bool, a == b}}
  defp aplicar("!=", {t, a}, {t, b}), do: {:ok, {:bool, a != b}}

  defp aplicar("&&", {:bool, a}, {:bool, b}), do: {:ok, {:bool, a and b}}
  defp aplicar("||", {:bool, a}, {:bool, b}), do: {:ok, {:bool, a or b}}

  # Cualquier otra combinación es un error de tipos
  defp aplicar(op, izq, der),
    do:
      {:error,
       "el operador '#{op}' requiere #{requiere(op)}, pero recibió #{tipo(izq)} y #{tipo(der)}"}

  defp operacion_numerica(op, a, b) do
    resultado =
      case op do
        "+" -> {:ok, a + b}
        "-" -> {:ok, a - b}
        "*" -> {:ok, a * b}
        "/" -> dividir(a, b)
      end

    case resultado do
      {:ok, numero} -> {:ok, {:num, numero}}
      {:error, motivo} -> {:error, motivo}
    end
  rescue
    ArithmeticError ->
      {:error, "la operación no se puede representar en el rango numérico del intérprete"}
  end

  defp dividir(0, b) when is_integer(b), do: {:ok, 0.0}

  defp dividir(a, b) when is_integer(a) and is_integer(b) do
    try do
      {:ok, a / b}
    rescue
      ArithmeticError -> division_escalada(a, b)
    end
  end

  defp dividir(a, b), do: {:ok, a / b}

  defp division_escalada(a, b) do
    {mantisa_a, exponente_a} = normalizar(abs(a))
    {mantisa_b, exponente_b} = normalizar(abs(b))
    magnitud = mantisa_a / mantisa_b * :math.pow(10.0, exponente_a - exponente_b)
    signo = if a < 0 != b < 0, do: -1.0, else: 1.0
    resultado = signo * magnitud

    if resultado == 0.0 do
      {:error, "la operación no se puede representar en el rango numérico del intérprete"}
    else
      {:ok, resultado}
    end
  rescue
    ArithmeticError ->
      {:error, "la operación no se puede representar en el rango numérico del intérprete"}
  end

  defp normalizar(numero) do
    digitos = Integer.to_string(numero)
    prefijo = String.slice(digitos, 0, 16)
    {significativo, ""} = Float.parse(prefijo)
    mantisa = significativo / :math.pow(10.0, byte_size(prefijo) - 1)
    {mantisa, byte_size(digitos) - 1}
  end

  defp requiere(op) when op in ["&&", "||"], do: "booleanos"
  defp requiere(op) when op in ["==", "!="], do: "dos valores del mismo tipo"
  defp requiere(_op), do: "números"

  defp tipo({:num, _}), do: "un número"
  defp tipo({:bool, _}), do: "un booleano"
end
