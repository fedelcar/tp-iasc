Subastas - TP IASC
===================

## Resumen de la arquitectura
Hay dos modos para iniciar cada nodo: :primary y :secondary.

Cuando el nodo es primario, replica sus mensajes hacia el nodo que esta conectado a él mismo.

Si está en modo secundario, no replica sus mensajes, pero si el mismo ve que se cae el primario, asume su rol.

Para iniciar el nodo: ```iex --name fede@192.168.1.101 --cookie galleta -S mix``` (la cookie debe ser la misma para que se conozcan los nodos entre si)

Configurar el modo inicial y a quién se conecta en ```mix.exs```

## Tests
Hay un test por cada escenario descripto.
Correrlos con ```mix test```.

# Endpoints de la API
Default port: 3001 (o configurar el deseado en ```mix.exs```)

## Subastas
### POST /subastas - Crear Subasta
**Request:** JSON del tipo ```{ "name": "subasta",
                                "base_price": 100,
                                "duration": 5}``` (Duración en segundos)

**Response:** OK ```{"status":"created"}```

### GET /subastas/{name} - Ver Subasta
**Request:** ```subastas/subasta```

**Response:** OK ```{"name":"subasta", "price":"100", "duration":"5", "offerer":"no_offered_yet"}```

### POST /subastas/ofertar - Hacer una oferta
**Request:** JSON del tipo ```{"subasta": "subasta", "comprador": "Charly Garcia", "precio": 150}```

**Response:** OK ```{"status":"ok"}```

### POST /subastas/cancelar - Cancelar Subasta
**Request:** JSON del tipo ```{ "name": "subasta",}```

**Response:** OK ```{"status":"cancelled"}```



## Compradores
### POST /compradores - Registrar Comprador
**Request:** JSON del tipo ```{ "name": "Charly",
                                "contacto": "carlos@garcia.com"}```

**Response:** OK ```{"status":"created"}```

### GET /compradores/{name} - Ver Comprador
**Request:** ```compradores/Charly```

**Response:** OK ```{"name":"Charly", "contacto":"carlos@garcia.com"}```



## Endpoint para testear el crasheo
### POST /crash
Chau!!! Tira una excepción que hace crashear la app.
