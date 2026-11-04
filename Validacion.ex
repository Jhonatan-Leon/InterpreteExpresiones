defmodule Validacion do
  def validar(texto) do #Esta es la funcion publica, la que se llama desde otros lados. Devuelve :ok o {:error, posicion, motivo}
    if String.trim(texto) == "" do #si al quitarle los espacios no queda nada es porque la expresion esta vacia
      {:error, 1, "expresion vacia"}
    else
      revisar(String.graphemes(texto), 1, []) #String.graphemes parte el texto en caracteres sueltos, asi la "ñ" cuenta como 1 y no como 2 bytes
      #el 1 es la posicion en la que vamos y [] es la pila de papelitos donde se anota la posicion de cada "(" que se abre
    end
  end

  defp revisar([], _pos, []), do: :ok #Este es el caso final cuando ya no quedan caracteres por revisar y tampoco quedo ningun "(" sin cerrar, todo bien :)

  defp revisar([], _pos, pila), do: {:error, ultimo(pila), "parentesis abierto sin cerrar"} #Tambien es caso final pero quedaron papelitos en la pila,
  #o sea que hay "(" que nunca se cerraron. Se reporta el que se abrio primero, que es el que quedo hasta el fondo

  defp revisar(["(" | resto], pos, pila), do: revisar(resto, pos + 1, [pos | pila]) #llega un "(", se anota su posicion en un papelito encima de la pila y sigue

  defp revisar([")" | _resto], pos, []), do: {:error, pos, "parentesis de cierre sin apertura"} #llega un ")" pero la pila esta vacia, no hay ningun "(" que cerrar

  defp revisar([")" | resto], pos, [_abierto | pila]), do: revisar(resto, pos + 1, pila) #llega un ")" y si hay papelitos, cierra el de encima (el ultimo que se abrio) y lo bota

  defp revisar([c | resto], pos, pila) do #Este es el caso de trabajo para cualquier otro caracter
    if permitido?(c) do #pregunta que si el caracter esta en la lista de los que se dejan
      revisar(resto, pos + 1, pila) #si se deja, sigue con el siguiente
    else
      {:error, pos, "caracter no permitido: '#{c}'"} #si no, se detiene aca mismo y dice en que posicion fue
    end
  end

  # aca se dejan los digitos, los espacios, los simbolos de los operadores y las letras (por el true y el false)
  # si alguien escribe una palabra como "abc" aca pasa, pero el tokenizador la atrapa despues
  defp permitido?(c) do
    String.contains?("0123456789 \t+-*/<>=!&|", c) or letra?(c)
  end

  defp letra?(c), do: (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") #pregunta que si es una letra sin tilde, minuscula o mayuscula

  # aca cree la funcion ultimo para sacar el papelito del fondo de la pila, que es el "(" que se abrio primero
  # (con un List.last seria una linea, pero aca no se puede usar Enum ni nada parecido)
  defp ultimo([x]), do: x #si solo queda un papelito, ese es el del fondo
  defp ultimo([_ | resto]), do: ultimo(resto) #si hay mas, se quita el de encima y se sigue buscando
end
