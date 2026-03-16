package com.datafish.inventory.service;

import com.datafish.inventory.model.InventoryItem;
import com.datafish.inventory.model.InventoryTransaction;
import com.datafish.inventory.repository.InventoryRepository;
import com.datafish.inventory.repository.TransactionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;

@Service
public class InventoryService {

    @Autowired
    private InventoryRepository inventoryRepository;

    @Autowired
    private TransactionRepository transactionRepository;

    @Value("${inventory.low-stock-threshold:10}")
    private int lowStockThreshold;

    public List<InventoryItem> getAllItems() {
        return inventoryRepository.findAll();
    }

    public Optional<InventoryItem> getByProductId(Long productId) {
        return inventoryRepository.findByProductId(productId);
    }

    public List<InventoryItem> getLowStockItems() {
        return inventoryRepository.findLowStockItems();
    }

    @Transactional
    public InventoryItem createOrUpdate(InventoryItem item) {
        Optional<InventoryItem> existing = inventoryRepository.findByProductId(item.getProductId());
        
        if (existing.isPresent()) {
            InventoryItem existingItem = existing.get();
            existingItem.setQuantity(item.getQuantity());
            existingItem.setProductName(item.getProductName());
            existingItem.setWarehouseLocation(item.getWarehouseLocation());
            existingItem.setSupplier(item.getSupplier());
            existingItem.setReorderLevel(item.getReorderLevel());
            existingItem.setReorderQuantity(item.getReorderQuantity());
            return inventoryRepository.save(existingItem);
        }
        
        return inventoryRepository.save(item);
    }

    @Transactional
    public InventoryItem receiveStock(Long productId, int quantity, String notes) {
        InventoryItem item = inventoryRepository.findByProductId(productId)
                .orElseThrow(() -> new RuntimeException("Product not found in inventory: " + productId));

        item.setQuantity(item.getQuantity() + quantity);
        inventoryRepository.save(item);

        // Log transaction
        InventoryTransaction transaction = new InventoryTransaction();
        transaction.setProductId(productId);
        transaction.setType(InventoryTransaction.TransactionType.RECEIVED);
        transaction.setQuantity(quantity);
        transaction.setNotes(notes);
        transactionRepository.save(transaction);

        return item;
    }

    @Transactional
    public InventoryItem reserveStock(Long productId, int quantity, String orderId) {
        InventoryItem item = inventoryRepository.findByProductId(productId)
                .orElseThrow(() -> new RuntimeException("Product not found in inventory: " + productId));

        if (item.getAvailableQuantity() < quantity) {
            throw new RuntimeException("Insufficient stock. Available: " + item.getAvailableQuantity());
        }

        item.setReservedQuantity(item.getReservedQuantity() + quantity);
        inventoryRepository.save(item);

        // Log transaction
        InventoryTransaction transaction = new InventoryTransaction();
        transaction.setProductId(productId);
        transaction.setType(InventoryTransaction.TransactionType.RESERVED);
        transaction.setQuantity(quantity);
        transaction.setReferenceId(orderId);
        transactionRepository.save(transaction);

        return item;
    }

    @Transactional
    public InventoryItem releaseReservation(Long productId, int quantity, String orderId) {
        InventoryItem item = inventoryRepository.findByProductId(productId)
                .orElseThrow(() -> new RuntimeException("Product not found in inventory: " + productId));

        int newReserved = Math.max(0, item.getReservedQuantity() - quantity);
        item.setReservedQuantity(newReserved);
        inventoryRepository.save(item);

        // Log transaction
        InventoryTransaction transaction = new InventoryTransaction();
        transaction.setProductId(productId);
        transaction.setType(InventoryTransaction.TransactionType.RELEASED);
        transaction.setQuantity(quantity);
        transaction.setReferenceId(orderId);
        transactionRepository.save(transaction);

        return item;
    }

    @Transactional
    public InventoryItem confirmSale(Long productId, int quantity, String orderId) {
        InventoryItem item = inventoryRepository.findByProductId(productId)
                .orElseThrow(() -> new RuntimeException("Product not found in inventory: " + productId));

        // Reduce both quantity and reserved
        item.setQuantity(item.getQuantity() - quantity);
        item.setReservedQuantity(Math.max(0, item.getReservedQuantity() - quantity));
        inventoryRepository.save(item);

        // Log transaction
        InventoryTransaction transaction = new InventoryTransaction();
        transaction.setProductId(productId);
        transaction.setType(InventoryTransaction.TransactionType.SOLD);
        transaction.setQuantity(quantity);
        transaction.setReferenceId(orderId);
        transactionRepository.save(transaction);

        return item;
    }

    @Transactional
    public InventoryItem adjustStock(Long productId, int newQuantity, String reason) {
        InventoryItem item = inventoryRepository.findByProductId(productId)
                .orElseThrow(() -> new RuntimeException("Product not found in inventory: " + productId));

        int adjustment = newQuantity - item.getQuantity();
        item.setQuantity(newQuantity);
        inventoryRepository.save(item);

        // Log transaction
        InventoryTransaction transaction = new InventoryTransaction();
        transaction.setProductId(productId);
        transaction.setType(InventoryTransaction.TransactionType.ADJUSTED);
        transaction.setQuantity(adjustment);
        transaction.setNotes(reason);
        transactionRepository.save(transaction);

        return item;
    }

    public List<InventoryTransaction> getTransactionHistory(Long productId) {
        return transactionRepository.findByProductIdOrderByCreatedAtDesc(productId);
    }

    public List<InventoryTransaction> getRecentTransactions(int hours) {
        LocalDateTime since = LocalDateTime.now().minusHours(hours);
        return transactionRepository.findRecentTransactions(since);
    }

    public Map<String, Object> getInventoryStats() {
        Map<String, Object> stats = new HashMap<>();
        
        Long totalStock = inventoryRepository.getTotalStock();
        Long totalReserved = inventoryRepository.getTotalReserved();
        List<InventoryItem> lowStock = inventoryRepository.findLowStockItems();
        
        stats.put("totalItems", inventoryRepository.count());
        stats.put("totalStock", totalStock != null ? totalStock : 0);
        stats.put("totalReserved", totalReserved != null ? totalReserved : 0);
        stats.put("totalAvailable", (totalStock != null ? totalStock : 0) - (totalReserved != null ? totalReserved : 0));
        stats.put("lowStockCount", lowStock.size());
        stats.put("lowStockItems", lowStock);
        
        // Transaction stats
        stats.put("totalReceived", transactionRepository.countByType(InventoryTransaction.TransactionType.RECEIVED));
        stats.put("totalSold", transactionRepository.countByType(InventoryTransaction.TransactionType.SOLD));
        
        return stats;
    }

    /**
     * Scheduled batch job to sync inventory with warehouse
     * This simulates a real-world batch processing scenario
     */
    @Scheduled(fixedRateString = "${inventory.batch.sync-interval-ms:60000}")
    public void syncWithWarehouse() {
        System.out.println("📦 [BATCH] Starting warehouse inventory sync...");
        
        List<InventoryItem> items = inventoryRepository.findAll();
        int syncedCount = 0;
        
        for (InventoryItem item : items) {
            // Simulate sync operation
            item.setLastSyncedAt(LocalDateTime.now());
            inventoryRepository.save(item);
            
            // Log sync transaction
            InventoryTransaction transaction = new InventoryTransaction();
            transaction.setProductId(item.getProductId());
            transaction.setType(InventoryTransaction.TransactionType.SYNCED);
            transaction.setQuantity(0);
            transaction.setNotes("Batch sync with warehouse");
            transactionRepository.save(transaction);
            
            syncedCount++;
        }
        
        System.out.println("📦 [BATCH] Warehouse sync completed. Items synced: " + syncedCount);
    }

    /**
     * Scheduled job to check for low stock and trigger alerts
     */
    @Scheduled(fixedRate = 120000) // Every 2 minutes
    public void checkLowStock() {
        System.out.println("📦 [BATCH] Checking for low stock items...");
        
        List<InventoryItem> lowStockItems = inventoryRepository.findLowStockItems();
        
        if (!lowStockItems.isEmpty()) {
            System.out.println("⚠️ [ALERT] Found " + lowStockItems.size() + " low stock items:");
            for (InventoryItem item : lowStockItems) {
                System.out.println("   - " + item.getProductName() + 
                        " (Available: " + item.getAvailableQuantity() + 
                        ", Reorder Level: " + item.getReorderLevel() + ")");
            }
        } else {
            System.out.println("📦 [BATCH] All stock levels healthy.");
        }
    }
}




