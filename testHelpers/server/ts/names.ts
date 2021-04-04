/* Copyright (c) 2020, VRAI Labs and/or its affiliates. All rights reserved.
 *
 * This software is licensed under the Apache License, Version 2.0 (the
 * "License") as published by the Apache Software Foundation.
 *
 * You may not use this file except in compliance with the License. You may
 * obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */
const Names = JSON.parse(`[{
    "firstName": "Vince",
    "lastName": "Park",
    "gender": "m"
},
    {
        "firstName": "Long",
        "lastName": "Bailey",
        "gender": "m"
    },
    {
        "firstName": "Dannie",
        "lastName": "Fowler",
        "gender": "m"
    },
    {
        "firstName": "Marcus",
        "lastName": "Osborne",
        "gender": "m"
    },
    {
        "firstName": "Kraig",
        "lastName": "Underwood",
        "gender": "m"
    },
    {
        "firstName": "Keith",
        "lastName": "Anthony",
        "gender": "m"
    },
    {
        "firstName": "Giovanni",
        "lastName": "Cochran",
        "gender": "m"
    },
    {
        "firstName": "Ronnie",
        "lastName": "Daniel",
        "gender": "m"
    },
    {
        "firstName": "Dave",
        "lastName": "Campos",
        "gender": "m"
    },
    {
        "firstName": "Angel",
        "lastName": "Poole",
        "gender": "m"
    },
    {
        "firstName": "Delmar",
        "lastName": "Owens",
        "gender": "m"
    },
    {
        "firstName": "Garret",
        "lastName": "Avila",
        "gender": "m"
    },
    {
        "firstName": "Barney",
        "lastName": "Vega",
        "gender": "m"
    },
    {
        "firstName": "Pat",
        "lastName": "Lewis",
        "gender": "m"
    },
    {
        "firstName": "Willard",
        "lastName": "Houston",
        "gender": "m"
    },
    {
        "firstName": "Millard",
        "lastName": "Marsh",
        "gender": "m"
    },
    {
        "firstName": "Enoch",
        "lastName": "Simmons",
        "gender": "m"
    },
    {
        "firstName": "Sherman",
        "lastName": "Aguilar",
        "gender": "m"
    },
    {
        "firstName": "Raymond",
        "lastName": "Lang",
        "gender": "m"
    },
    {
        "firstName": "Emil",
        "lastName": "Johnston",
        "gender": "m"
    },
    {
        "firstName": "Samual",
        "lastName": "Nguyen",
        "gender": "m"
    },
    {
        "firstName": "Abdul",
        "lastName": "Mckee",
        "gender": "m"
    },
    {
        "firstName": "Jefferey",
        "lastName": "Fox",
        "gender": "m"
    },
    {
        "firstName": "Darell",
        "lastName": "Smith",
        "gender": "m"
    },
    {
        "firstName": "Al",
        "lastName": "Peck",
        "gender": "m"
    },
    {
        "firstName": "Clemente",
        "lastName": "Reid",
        "gender": "m"
    },
    {
        "firstName": "Nathanial",
        "lastName": "Ramirez",
        "gender": "m"
    },
    {
        "firstName": "Royal",
        "lastName": "Faulkner",
        "gender": "m"
    },
    {
        "firstName": "Jonathon",
        "lastName": "Cherry",
        "gender": "m"
    },
    {
        "firstName": "Darrel",
        "lastName": "Barker",
        "gender": "m"
    },
    {
        "firstName": "Floyd",
        "lastName": "Shields",
        "gender": "m"
    },
    {
        "firstName": "Amos",
        "lastName": "Spears",
        "gender": "m"
    },
    {
        "firstName": "Jimmy",
        "lastName": "Wiggins",
        "gender": "m"
    },
    {
        "firstName": "Bennie",
        "lastName": "Stout",
        "gender": "m"
    },
    {
        "firstName": "Elmer",
        "lastName": "Arellano",
        "gender": "m"
    },
    {
        "firstName": "Julian",
        "lastName": "Frey",
        "gender": "m"
    },
    {
        "firstName": "Raymon",
        "lastName": "Hansen",
        "gender": "m"
    },
    {
        "firstName": "Joe",
        "lastName": "Duke",
        "gender": "m"
    },
    {
        "firstName": "Edgardo",
        "lastName": "Valencia",
        "gender": "m"
    },
    {
        "firstName": "Tomas",
        "lastName": "Quinn",
        "gender": "m"
    },
    {
        "firstName": "Kristofer",
        "lastName": "Glenn",
        "gender": "m"
    },
    {
        "firstName": "Micah",
        "lastName": "Stanley",
        "gender": "m"
    },
    {
        "firstName": "Pasquale",
        "lastName": "Estrada",
        "gender": "m"
    },
    {
        "firstName": "Erich",
        "lastName": "Galvan",
        "gender": "m"
    },
    {
        "firstName": "Mitchel",
        "lastName": "Kidd",
        "gender": "m"
    },
    {
        "firstName": "Dale",
        "lastName": "Guerrero",
        "gender": "m"
    },
    {
        "firstName": "Arthur",
        "lastName": "Frederick",
        "gender": "m"
    },
    {
        "firstName": "Dwayne",
        "lastName": "Willis",
        "gender": "m"
    },
    {
        "firstName": "Marlin",
        "lastName": "Carpenter",
        "gender": "m"
    },
    {
        "firstName": "Elden",
        "lastName": "Strong",
        "gender": "m"
    },
    {
        "firstName": "Rocco",
        "lastName": "Odonnell",
        "gender": "m"
    },
    {
        "firstName": "Beau",
        "lastName": "Hogan",
        "gender": "m"
    },
    {
        "firstName": "Henry",
        "lastName": "Ruiz",
        "gender": "m"
    },
    {
        "firstName": "Dillon",
        "lastName": "Pena",
        "gender": "m"
    },
    {
        "firstName": "Jewell",
        "lastName": "Larson",
        "gender": "m"
    },
    {
        "firstName": "Ronny",
        "lastName": "Beard",
        "gender": "m"
    },
    {
        "firstName": "Eloy",
        "lastName": "Moody",
        "gender": "m"
    },
    {
        "firstName": "Duncan",
        "lastName": "Burton",
        "gender": "m"
    },
    {
        "firstName": "Bruce",
        "lastName": "Duffy",
        "gender": "m"
    },
    {
        "firstName": "Marcellus",
        "lastName": "Nixon",
        "gender": "m"
    },
    {
        "firstName": "Grant",
        "lastName": "Kirby",
        "gender": "m"
    },
    {
        "firstName": "Ambrose",
        "lastName": "Barton",
        "gender": "m"
    },
    {
        "firstName": "Nestor",
        "lastName": "Mercado",
        "gender": "m"
    },
    {
        "firstName": "Bradford",
        "lastName": "Vincent",
        "gender": "m"
    },
    {
        "firstName": "Lamont",
        "lastName": "Murphy",
        "gender": "m"
    },
    {
        "firstName": "Domingo",
        "lastName": "Arias",
        "gender": "m"
    },
    {
        "firstName": "Brant",
        "lastName": "Olsen",
        "gender": "m"
    },
    {
        "firstName": "Stephen",
        "lastName": "Hicks",
        "gender": "m"
    },
    {
        "firstName": "Elliot",
        "lastName": "Robles",
        "gender": "m"
    },
    {
        "firstName": "Paul",
        "lastName": "Glover",
        "gender": "m"
    },
    {
        "firstName": "Spencer",
        "lastName": "Rollins",
        "gender": "m"
    },
    {
        "firstName": "Tracey",
        "lastName": "Cook",
        "gender": "m"
    },
    {
        "firstName": "Kelvin",
        "lastName": "Anderson",
        "gender": "m"
    },
    {
        "firstName": "Rogelio",
        "lastName": "Bray",
        "gender": "m"
    },
    {
        "firstName": "Ralph",
        "lastName": "Mcneil",
        "gender": "m"
    },
    {
        "firstName": "Bradly",
        "lastName": "Phillips",
        "gender": "m"
    },
    {
        "firstName": "Donnell",
        "lastName": "Thornton",
        "gender": "m"
    },
    {
        "firstName": "Curt",
        "lastName": "Hudson",
        "gender": "m"
    },
    {
        "firstName": "Keneth",
        "lastName": "Hoffman",
        "gender": "m"
    },
    {
        "firstName": "Rafael",
        "lastName": "Maxwell",
        "gender": "m"
    },
    {
        "firstName": "Cortez",
        "lastName": "Morris",
        "gender": "m"
    },
    {
        "firstName": "Danny",
        "lastName": "Gould",
        "gender": "m"
    },
    {
        "firstName": "Willis",
        "lastName": "Montoya",
        "gender": "m"
    },
    {
        "firstName": "Shelby",
        "lastName": "Hahn",
        "gender": "m"
    },
    {
        "firstName": "Ronald",
        "lastName": "Mccullough",
        "gender": "m"
    },
    {
        "firstName": "Glenn",
        "lastName": "Welch",
        "gender": "m"
    },
    {
        "firstName": "Irvin",
        "lastName": "Burns",
        "gender": "m"
    },
    {
        "firstName": "Arlen",
        "lastName": "Garrett",
        "gender": "m"
    },
    {
        "firstName": "Gary",
        "lastName": "Stone",
        "gender": "m"
    },
    {
        "firstName": "Ike",
        "lastName": "Berg",
        "gender": "m"
    },
    {
        "firstName": "Augusta",
        "lastName": "Costa",
        "gender": "f"
    },
    {
        "firstName": "Juliana",
        "lastName": "Malone",
        "gender": "f"
    },
    {
        "firstName": "Selena",
        "lastName": "Riddle",
        "gender": "f"
    },
    {
        "firstName": "Leonor",
        "lastName": "Stanton",
        "gender": "f"
    },
    {
        "firstName": "Joyce",
        "lastName": "Sandoval",
        "gender": "f"
    },
    {
        "firstName": "Cecile",
        "lastName": "Alvarez",
        "gender": "f"
    },
    {
        "firstName": "Jeanne",
        "lastName": "Mccall",
        "gender": "f"
    },
    {
        "firstName": "Rebekah",
        "lastName": "Clark",
        "gender": "f"
    },
    {
        "firstName": "Alia",
        "lastName": "Jadhav",
        "gender": "f"
    },
    {
        "firstName": "Ina",
        "lastName": "Mclaughlin",
        "gender": "f"
    },
    {
        "firstName": "Merle",
        "lastName": "Wall",
        "gender": "f"
    },
    {
        "firstName": "Leona",
        "lastName": "Wiley",
        "gender": "f"
    },
    {
        "firstName": "Bessie",
        "lastName": "Juarez",
        "gender": "f"
    },
    {
        "firstName": "Millie",
        "lastName": "Curtis",
        "gender": "f"
    },
    {
        "firstName": "Juliet",
        "lastName": "Warner",
        "gender": "f"
    },
    {
        "firstName": "Leta",
        "lastName": "Blevins",
        "gender": "f"
    },
    {
        "firstName": "Deanna",
        "lastName": "Erickson",
        "gender": "f"
    },
    {
        "firstName": "Amanda",
        "lastName": "Pierce",
        "gender": "f"
    },
    {
        "firstName": "Lily",
        "lastName": "Benjamin",
        "gender": "f"
    },
    {
        "firstName": "Bettie",
        "lastName": "Garcia",
        "gender": "f"
    },
    {
        "firstName": "Silvia",
        "lastName": "Rojas",
        "gender": "f"
    },
    {
        "firstName": "Iris",
        "lastName": "Merritt",
        "gender": "f"
    },
    {
        "firstName": "Malinda",
        "lastName": "Braun",
        "gender": "f"
    },
    {
        "firstName": "Monica",
        "lastName": "Andrade",
        "gender": "f"
    },
    {
        "firstName": "Sharron",
        "lastName": "Stewart",
        "gender": "f"
    },
    {
        "firstName": "Anu",
        "lastName": "Muzumdar",
        "gender": "f"
    },
    {
        "firstName": "Susanna",
        "lastName": "Hooper",
        "gender": "f"
    },
    {
        "firstName": "Melinda",
        "lastName": "Villegas",
        "gender": "f"
    },
    {
        "firstName": "Jewel",
        "lastName": "Daniels",
        "gender": "f"
    },
    {
        "firstName": "Deirdre",
        "lastName": "Conrad",
        "gender": "f"
    },
    {
        "firstName": "Jackie",
        "lastName": "Long",
        "gender": "f"
    },
    {
        "firstName": "Herminia",
        "lastName": "Freeman",
        "gender": "f"
    },
    {
        "firstName": "Elena",
        "lastName": "Harding",
        "gender": "f"
    },
    {
        "firstName": "Tamara",
        "lastName": "Case",
        "gender": "f"
    },
    {
        "firstName": "Lelia",
        "lastName": "Franco",
        "gender": "f"
    },
    {
        "firstName": "Marta",
        "lastName": "Morton",
        "gender": "f"
    },
    {
        "firstName": "Edna",
        "lastName": "Olson",
        "gender": "f"
    },
    {
        "firstName": "Corine",
        "lastName": "Cunningham",
        "gender": "f"
    },
    {
        "firstName": "Julie",
        "lastName": "Conner",
        "gender": "f"
    },
    {
        "firstName": "Rebecca",
        "lastName": "Hahn",
        "gender": "f"
    },
    {
        "firstName": "Corinne",
        "lastName": "Good",
        "gender": "f"
    },
    {
        "firstName": "Wilda",
        "lastName": "Atkinson",
        "gender": "f"
    },
    {
        "firstName": "Elva",
        "lastName": "Terrell",
        "gender": "f"
    },
    {
        "firstName": "Shirley",
        "lastName": "Lynn",
        "gender": "f"
    },
    {
        "firstName": "Liza",
        "lastName": "Fox",
        "gender": "f"
    },
    {
        "firstName": "Aishwarya",
        "lastName": "Valimbe",
        "gender": "f"
    },
    {
        "firstName": "Elma",
        "lastName": "Osborn",
        "gender": "f"
    },
    {
        "firstName": "Josefa",
        "lastName": "Rose",
        "gender": "f"
    },
    {
        "firstName": "Edwina",
        "lastName": "Vargas",
        "gender": "f"
    },
    {
        "firstName": "Bonnie",
        "lastName": "Huber",
        "gender": "f"
    },
    {
        "firstName": "Maria",
        "lastName": "Fields",
        "gender": "f"
    },
    {
        "firstName": "Hollie",
        "lastName": "Cordova",
        "gender": "f"
    },
    {
        "firstName": "Sherrie",
        "lastName": "Gomez",
        "gender": "f"
    },
    {
        "firstName": "Cara",
        "lastName": "Bauer",
        "gender": "f"
    },
    {
        "firstName": "Ladonna",
        "lastName": "Kane",
        "gender": "f"
    },
    {
        "firstName": "Daisy",
        "lastName": "Frazier",
        "gender": "f"
    },
    {
        "firstName": "Leila",
        "lastName": "Melton",
        "gender": "f"
    },
    {
        "firstName": "Rosanna",
        "lastName": "Lindsey",
        "gender": "f"
    },
    {
        "firstName": "Eileen",
        "lastName": "Cameron",
        "gender": "f"
    },
    {
        "firstName": "Crystal",
        "lastName": "Newton",
        "gender": "f"
    },
    {
        "firstName": "Roberta",
        "lastName": "Roth",
        "gender": "f"
    },
    {
        "firstName": "Lee",
        "lastName": "Acevedo",
        "gender": "f"
    },
    {
        "firstName": "Milagros",
        "lastName": "Key",
        "gender": "f"
    },
    {
        "firstName": "Adela",
        "lastName": "Oconnor",
        "gender": "f"
    },
    {
        "firstName": "Rachael",
        "lastName": "Miles",
        "gender": "f"
    },
    {
        "firstName": "Lessie",
        "lastName": "Marquez",
        "gender": "f"
    },
    {
        "firstName": "Evelyn",
        "lastName": "Wood",
        "gender": "f"
    },
    {
        "firstName": "Hope",
        "lastName": "Riley",
        "gender": "f"
    },
    {
        "firstName": "Lucile",
        "lastName": "Wilson",
        "gender": "f"
    },
    {
        "firstName": "Eve",
        "lastName": "Flowers",
        "gender": "f"
    },
    {
        "firstName": "Vilma",
        "lastName": "Vang",
        "gender": "f"
    },
    {
        "firstName": "Jordan",
        "lastName": "Bryant",
        "gender": "f"
    },
    {
        "firstName": "Adrienne",
        "lastName": "Bradshaw",
        "gender": "f"
    },
    {
        "firstName": "Kelsey",
        "lastName": "Larson",
        "gender": "f"
    },
    {
        "firstName": "Erma",
        "lastName": "Thomas",
        "gender": "f"
    },
    {
        "firstName": "Marlene",
        "lastName": "Acosta",
        "gender": "f"
    },
    {
        "firstName": "Rosie",
        "lastName": "Boyer",
        "gender": "f"
    },
    {
        "firstName": "Manuela",
        "lastName": "Pineda",
        "gender": "f"
    },
    {
        "firstName": "Cecelia",
        "lastName": "Nelson",
        "gender": "f"
    },
    {
        "firstName": "Noelle",
        "lastName": "Avila",
        "gender": "f"
    },
    {
        "firstName": "Traci",
        "lastName": "Cobb",
        "gender": "f"
    },
    {
        "firstName": "Elba",
        "lastName": "Berry",
        "gender": "f"
    },
    {
        "firstName": "Jenny",
        "lastName": "Lucero",
        "gender": "f"
    },
    {
        "firstName": "Valerie",
        "lastName": "Dunn",
        "gender": "f"
    }]`);

export default Names;