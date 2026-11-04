defmodule Tokenizador do
  # aca se parte la expresion en piezas (tokens), como cortar una frase en palabras. Cada pieza queda como {tipo, valor, posicion}:
  #   {:numero, 25, 1}  {:booleano, true, 4}  {:operador, "&&", 9}  {:abre, "(", 1}  {:cierra, ")", 7}
  # devuelve {:ok, tokens} o {:error, posicion, motivo}
  def tokenizar(texto), do: tokenizar(String.graphemes(texto), 1, []) #Esta es la primera iteracion, la funcion publica. Los caracteres son la fila
  #de letras a revisar, el 1 es la posicion en la que vamos y [] es la caja donde se van guardando las piezas

  defp tokenizar([], _pos, tokens), do: {:ok, invertir(tokens)} #Este es el caso final cuando ya no quedan caracteres, las piezas quedaron al reves
  #porque cada una se mete al inicio de la caja, por eso se invierten

  defp tokenizar([" " | resto], pos, tokens), do: tokenizar(resto, pos + 1, tokens) #los espacios no son piezas, solo se saltan
  defp tokenizar(["\t" | resto], pos, tokens), do: tokenizar(resto, pos + 1, tokens) #las tabulaciones tambien

  # aca primero se pregunta por los operadores de dos caracteres, si no "<=" se partiria en "<" y "=" que serian dos piezas
  defp tokenizar(["<", "=" | resto], pos, tokens), do: tokenizar(resto, pos + 2, [{:operador, "<=", pos} | tokens]) #avanza 2 porque se comio dos caracteres
  defp tokenizar([">", "=" | resto], pos, tokens), do: tokenizar(resto, pos + 2, [{:operador, ">=", pos} | tokens])
  defp tokenizar(["=", "=" | resto], pos, tokens), do: tokenizar(resto, pos + 2, [{:operador, "==", pos} | tokens])
  defp tokenizar(["!", "=" | resto], pos, tokens), do: tokenizar(resto, pos + 2, [{:operador, "!=", pos} | tokens])
  defp tokenizar(["&", "&" | resto], pos, tokens), do: tokenizar(resto, pos + 2, [{:operador, "&&", pos} | tokens])
  defp tokenizar(["|", "|" | resto], pos, tokens), do: tokenizar(resto, pos + 2, [{:operador, "||", pos} | tokens])

  # si llego hasta aca con un "&", "|" o "=" es porque venia solo, y esos solo existen en pareja
  defp tokenizar(["&" | _], pos, _tokens), do: {:error, pos, "operador incompleto '&', se esperaba '&&'"}
  defp tokenizar(["|" | _], pos, _tokens), do: {:error, pos, "operador incompleto '|', se esperaba '||'"}
  defp tokenizar(["=" | _], pos, _tokens), do: {:error, pos, "operador incompleto '=', se esperaba '=='"}

  defp tokenizar(["(" | resto], pos, tokens), do: tokenizar(resto, pos + 1, [{:abre, "(", pos} | tokens]) #parentesis que abre a la caja
  defp tokenizar([")" | resto], pos, tokens), do: tokenizar(resto, pos + 1, [{:cierra, ")", pos} | tokens]) #parentesis que cierra a la caja

  defp tokenizar([c | resto], pos, tokens) when c in ["+", "-", "*", "/", "<", ">", "!"], #los operadores de un solo caracter
    do: tokenizar(resto, pos + 1, [{:operador, c, pos} | tokens])

  defp tokenizar([c | _] = lista, pos, tokens) do #Este es el caso de trabajo para numeros y palabras, que pueden tener varios caracteres
    cond do
      digito?(c) -> #pregunta que si empieza un numero
        {digitos, resto, largo} = juntar(lista, &digito?/1, "", 0) #junta todos los digitos seguidos, asi "25" es una sola pieza y no dos
        tokenizar(resto, pos + largo, [{:numero, String.to_integer(digitos), pos} | tokens]) #lo mete a la caja ya como numero y avanza lo que midio

      letra?(c) -> #pregunta que si empieza una palabra
        {palabra, resto, largo} = juntar(lista, &letra?/1, "", 0) #junta las letras seguidas

        case palabra do #las unicas palabras que existen son true y false
          "true" -> tokenizar(resto, pos + largo, [{:booleano, true, pos} | tokens])
          "false" -> tokenizar(resto, pos + largo, [{:booleano, false, pos} | tokens])
          _ -> {:error, pos, "palabra no reconocida: '#{palabra}', solo se aceptan true y false"} #cualquier otra como "abc" o "True" es error
        end

      true -> # En cualquier otro caso es un caracter raro (no deberia pasar porque la validacion ya lo atrapa, pero por si acaso)
        {:error, pos, "caracter no permitido: '#{c}'"}
    end
  end

  # aca cree juntar, que va tomando caracteres mientras cumplan la condicion (ser digito o ser letra)
  # devuelve {lo que junto, lo que sobro, cuantos caracteres tomo}, el largo sirve para saber cuanto avanzar la posicion
  defp juntar([c | resto] = lista, condicion, acumulado, largo) do
    if condicion.(c) do #si el caracter cumple, se pega a lo que lleva y sigue
      juntar(resto, condicion, acumulado <> c, largo + 1)
    else
      {acumulado, lista, largo} #si no cumple, para y deja ese caracter para la siguiente pieza
    end
  end

  defp juntar([], _condicion, acumulado, largo), do: {acumulado, [], largo} #se acabo el texto mientras juntaba, devuelve lo que tenga

  defp digito?(c), do: c >= "0" and c <= "9" and byte_size(c) == 1 #pregunta que si es un digito del 0 al 9
  defp letra?(c), do: ((c >= "a" and c <= "z") or (c >= "A" and c <= "Z")) and byte_size(c) == 1 #pregunta que si es una letra sin tilde

  # el mismo invertir de itinerarios (todo seria mucho mas facil con un simple enum.reverse)
  defp invertir(lista), do: invertir(lista, [])
  defp invertir([], acumulado), do: acumulado
  defp invertir([x | resto], acumulado), do: invertir(resto, [x | acumulado])
end
