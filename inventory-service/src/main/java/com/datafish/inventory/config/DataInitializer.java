package com.datafish.inventory.config;

import com.datafish.inventory.model.InventoryItem;
import com.datafish.inventory.repository.InventoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private InventoryRepository inventoryRepository;

    @Override
    public void run(String... args) {
        if (inventoryRepository.count() == 0) {
            System.out.println("📦 Initializing inventory data...");
            initializeInventory();
            System.out.println("📦 Inventory data initialized with " + inventoryRepository.count() + " items");
        }
    }

    private void initializeInventory() {
        // Match product IDs from product-service
        createInventoryItem(1L, "Clownfish", 50, "A-1", "Ocean Suppliers Inc");
        createInventoryItem(2L, "Blue Tang", 35, "A-2", "Ocean Suppliers Inc");
        createInventoryItem(3L, "Angelfish", 40, "A-3", "Tropical Fish Co");
        createInventoryItem(4L, "Betta Fish", 75, "B-1", "Tropical Fish Co");
        createInventoryItem(5L, "Classic Goldfish", 100, "B-2", "Golden Fins Ltd");
        createInventoryItem(6L, "Fancy Goldfish", 45, "B-3", "Golden Fins Ltd");
        createInventoryItem(7L, "Standard Koi", 25, "C-1", "Koi Masters");
        createInventoryItem(8L, "Butterfly Koi", 15, "C-2", "Koi Masters");
        createInventoryItem(9L, "Lionfish", 12, "D-1", "Exotic Aquatics");
        createInventoryItem(10L, "Pufferfish", 20, "D-2", "Exotic Aquatics");
        createInventoryItem(11L, "Discus", 18, "D-3", "Exotic Aquatics");
        createInventoryItem(12L, "Arowana", 8, "D-4", "Exotic Aquatics");
        createInventoryItem(13L, "Neon Tetra", 200, "E-1", "Community Fish Supply");
        createInventoryItem(14L, "Guppy", 180, "E-2", "Community Fish Supply");
        createInventoryItem(15L, "Platy", 150, "E-3", "Community Fish Supply");
    }

    private void createInventoryItem(Long productId, String name, int quantity, 
                                     String location, String supplier) {
        InventoryItem item = new InventoryItem();
        item.setProductId(productId);
        item.setProductName(name);
        item.setQuantity(quantity);
        item.setReservedQuantity(0);
        item.setReorderLevel(10);
        item.setReorderQuantity(50);
        item.setWarehouseLocation(location);
        item.setSupplier(supplier);
        item.setLastUpdated(LocalDateTime.now());
        item.setLastSyncedAt(LocalDateTime.now());
        inventoryRepository.save(item);
    }
}




