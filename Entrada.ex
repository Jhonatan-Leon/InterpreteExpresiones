Code.require_file("Validacion.ex", __DIR__)
Code.require_file("Tokenizador.ex", __DIR__)

defmodule Entrada do
  # Esta es la funcion que se usa para cada linea que sale del stream de Lector.leer_expresiones
  # primero se valida y solo si pasa se parte en piezas. Devuelve {:ok, tokens} o {:error, posicion, motivo}
  def preparar({_linea, texto}) do
    with :ok <- Validacion.validar(texto) do # with va revisando en orden, si la validacion falla devuelve ese error y ni siquiera tokeniza
      Tokenizador.tokenizar(texto) # si paso la validacion, se parte en piezas
    end
  end
end
