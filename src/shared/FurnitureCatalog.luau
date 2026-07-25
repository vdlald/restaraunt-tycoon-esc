--!strict

export type FurnitureId = "Chair" | "DiningTable" | "KitchenTable" | "FlourBag" | "MeatSteakFridge" | "Trashcan"

export type FurnitureProduct = {
	Id: FurnitureId,
	Name: string,
	Price: number,
}

export type PurchaseResultReason = number

local FurnitureCatalog = {
	PurchaseResultReason = {
		None = 0,
		NotPreparation = 1,
		CountdownActive = 2,
		InsufficientCash = 3,
		InvalidFurniture = 4,
		PlacementActive = 5,
		PlacementFailed = 6,
	},
	Products = {
		{ Id = "Chair", Name = "Chair", Price = 10 },
		{ Id = "DiningTable", Name = "Dining Table", Price = 25 },
		{ Id = "KitchenTable", Name = "Kitchen Table", Price = 20 },
		{ Id = "FlourBag", Name = "Flour Bag", Price = 30 },
		{ Id = "MeatSteakFridge", Name = "Meat Steak Fridge", Price = 40 },
		{ Id = "Trashcan", Name = "Trashcan", Price = 15 },
	} :: { FurnitureProduct },
}

function FurnitureCatalog:GetProduct(id: string): FurnitureProduct?
	for _, product in self.Products do
		if product.Id == id then
			return product
		end
	end
	return nil
end

return FurnitureCatalog
