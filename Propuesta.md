# Propuesta UI - SerezCode

## Objetivo

Crear una interfaz de usuario para los proyecto con Serez Code y que sea moderna, intuitiva y fácil de usar. Que permita al usuario gestionar sus proyectos, paquetes y dependencias de manera eficiente.

## Requerimientos

- Que sea facil de diseñar y desarrollar.
- Que tenga mucha similitud a HTML, CSS y React js. (Pero usando serez-code).
- Que sea amigable al uso del dia a dia.
- Que permita crear componentes de UI reutilizables.
- Que concerve la filosofia de componetizar la UI.
- Permita crear componentes muy facilmente.

## Core UI
La UI sera una libreria donde mezcla parte de funcionalidades que ya funcionan en React Js con Serez-Code.
Lo importante es ver a la UI como interfaces.
Cada interface se autogenera internamente a partir de la llamada de la clase ``new Window()``.
Sus elementos son hijos de esa interface.

Utilizaran tantas ventanas como deseen, donde el peso en memoria lo lleve el interface, dado a que si no se actualiza nada, no aumentara el peso en el virtual dom si no hay interaccion.

Al usar Region based memoization, los componentes no se re-renderizan si no hay cambios en sus props.

Tendra su componente raiz, la cual, es su html por asi decirlo.
el css sera a parte de la estructura de datos y serez-code la parte logica.

## Componentes

Para el caso de nuevo componentes, sera al estilo de React js, con funciones y hooks, como useState o useEffect.

Cada componente sera reutilizable lo cual no necesita dependencia de nada ni nadie, simplemente es usando como dependencia si en la parte del interface es utilizado, como anidado.

Esas interfaces es el equivalente al DOM Virtual, ya que los cambios se orquestaran alli, es decir, que es transparente al desarrollador.

### Eventos
Los eventos para esta version 1.0.0 seran onClick, onChange, onSubmit, onPressKey, onPressEnter, onPressLeave, onHover, onUnHover, onMouseMove, onMouseEnter, onMouseLeave.

Esos eventos podran usar como desencadenadores y hacer sus propias funciones a raiz de eso.

> _**Nota técnica:** El soporte de teclado y mouse está implementado en serez-code v3.7.0 via `Terminal.readEvent()` (retorna KeyEvent o MouseEvent) y `Terminal.enableMouse(bool)`. serez-ui consume estas native fns internamente — el desarrollador solo usa los eventos de alto nivel._

## Estilo o Diseños
Utilizara la logica de CSS, pero con algunos ajustes, en la parte del diseño, se puede abrir compuertas logicas, donde el diseñador puede poner algo de logica, sin que sea demasiada, por ejemplo un condicional.

El render por default sera un public implicito, es decir que lo ponga el desarrollador o no, es indistinto, no va a permitir que sea private.

La clase Window, tiene por si misma render y children en primera instancia, ams tarde veremos mas que agregar, donde como dije antes render es un public implicito del tipo metodo y children es todo lo que hay dentro de los tags si es que lo necesitara, en el ejemplo lo utilizo para demostrar su valia.

En el caso de Button es un componente generado por la libreria.

El proceso de lo que es igual a JSX lo hara la propia libreria, donde cargara con todo el codigo base y el peso de la logica de renderizado y manejo de estado interno de la UI, haciendo que no dependa de nada y sea transparente para el desarrollador.

```serez-code
import {Window, Button} from './seres-code-ui';

 class Myform:Window {
    x = 1;

    public Myform(){
     super(render, children);   
    }

    render(){
        return (
            <div>
                <h1>{this.x}</h1>
                <Button onClick={() => this.x = this.x + 1}>Click me</Button>
                <div>
                    {this.children}
                </div>
            </div>
        );
    }
 }
```


```css

:import {
    my_form: myForm();
    x: my_form.x;
}

body (x == 1){
    color: white;
    background-color: blue;
}

body (x != 1){
    color: black;
    background-color: green;
}

h1{
    font-family: 'Roboto', sans-serif;
}
```

> _**Nota:** Esto funcionaria como **un CSS, pero con logica**. La idea **no es hacer un CSS desde 0**, sino **usar gran parte de lo que ya funciona en CSS**._