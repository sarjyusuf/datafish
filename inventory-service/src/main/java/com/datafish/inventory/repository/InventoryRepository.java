package com.datafish.inventory.repository;

import com.datafish.inventory.model.InventoryItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InventoryRepository extends JpaRepository<InventoryItem, Long> {

    Optional<InventoryItem> findByProductId(Long productId);

    @Query("SELECT i FROM InventoryItem i WHERE (i.quantity - i.reservedQuantity) <= i.reorderLevel")
    List<InventoryItem> findLowStockItems();

    @Query("SELECT i FROM InventoryItem i WHERE i.warehouseLocation = ?1")
    List<InventoryItem> findByWarehouseLocation(String location);

    @Query("SELECT i FROM InventoryItem i WHERE i.supplier = ?1")
    List<InventoryItem> findBySupplier(String supplier);

    @Query("SELECT SUM(i.quantity) FROM InventoryItem i")
    Long getTotalStock();

    @Query("SELECT SUM(i.reservedQuantity) FROM InventoryItem i")
    Long getTotalReserved();
}




