// PLA: pack-level content bridge.
// Goal: a colony that built Create's mill should not be blocked from Farmer's Delight's
// dough chain, and vice versa. Keep this file free of guesses: every id below was
// verified against the installed jars (Create: create:wheat_flour; FD: farmersdelight:wheat_dough).
//
// The water bucket keeps itself through the vanilla crafting remainder, so this recipe
// does not consume water.

ServerEvents.recipes(event => {
  // Create flour -> Farmer's Delight dough (mirrors FD's own wheat + water recipe).
  event.shapeless(Item.of('farmersdelight:wheat_dough', 2),
    ['create:wheat_flour', 'minecraft:water_bucket'])
})