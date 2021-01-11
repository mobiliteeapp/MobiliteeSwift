# Mobilitee - Nearest Bus Stops Feature

## BDD Specs

### Story: User requests to see the nearest bus stops

#### Narrative #1

> As an online user
> I want the app to load the nearest bus stops to my location
> So I can choose the bus stop that better fits my current needs

Scenarios (acceptance criteria):

```
Given the user has connectivity
When the user requests to see the nearest bus stops
Then the app should display a list of the nearest bus stops to the user's current location within a certain radius
```

## Use Cases

### Load Nearest Bus Stops From Remote Use Case

#### Data

* URL
* Latitude
* Longitude
* Radius

#### Primary course (happy path):

1. Execute "Load Nearest Bus Stops" command with above data.
2. System downloads data from the URL.
3. System validates downloaded data.
4. System creates nearest bus stops list from valid data.
5. System delivers nearest bus stops list.

#### No connectivity – error course (sad path):

1. System delivers error.

#### Invalid data – error course (sad path):

1. System delivers error.

#### Session expired - error course (sad path):

1. System delivers error.

## Flowchart

Not available.

## Architecture

Not available.

## Model Specs

### Nearest Bus Stop

| Property              | Type          |
|-----------------------|---------------|
| `id`                  | `Int`         |
| `latitude`            | `Double`      |
| `longitude`           | `Double`      |
| `name`                | `String`      |
| `address`             | `String`      |
| `distanceInMeters`    | `Int`         |
| `lines`               | `[NBSL]`      | (1)

(1) An array of Nearest Bus Stop Line objects (see below)

### Nearest Bus Stop Line

| Property      | Type      |
|---------------|-----------|
| `id`          | `String`  |
| `origin`      | `String`  |
| `destination` | `String`  |

## Payload contract

```
GET https://openapi.emtmadrid.es/v2/transport/busemtmad/stops/arroundxy/<longitude>/<latitude>/<radius>/

<longitude> expressed in decimal units (e.g. -3.640491)
<latitude> expressed in decimal units (e.g. 40.385558)
<radius> expressed in meters from current user's location (.e.g. 200)
```

On success:

```
200 RESPONSE

{
    "code": "00",
    "description": "a description",
    "data": [
        {
            "stopId": 1,
            "geometry": {
                "type": "Point",
                "coordinates": [
                    0.0,
                    0.0
                ]
            },
            "stopName": "a name",
            "address": "an address",
            "metersToPoint": 1,
            "lines": [
                {
                    "line": "a line number",
                    "label": "a line name",
                    "nameA": "a stop name",
                    "nameB": "another stop name",
                    "metersFromHeader": 1,
                    "to": "B"
                }
            ]
        },
        
		...
    ]
```

Warning: the first item in the `coordinates` array is the longitude, and the second is the latitude.

On session expired:

```
200 RESPONSE

{
    "code": "80",
    "description": "a description"
}
```

For more information you can see the [EMT Madrid API documentation](https://apidocs.emtmadrid.es/#api-Block_3_TRANSPORT_BUSEMTMAD-detail_of_stops_arround_geopoint).
