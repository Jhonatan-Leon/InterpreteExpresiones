defmodule Utilidades do
  @moduledoc """
  Funciones recursivas pequeñas que usan varios módulos, para no repetirlas.
  """

  @doc """
  Devuelve la lista en orden inverso.

  ## Parámetros
    - lista: la lista a voltear.

  """
  def invertir(lista), do: invertir(lista, [])

  defp invertir([], acc), do: acc
  defp invertir([x | resto], acc), do: invertir(resto, [x | acc])
end
