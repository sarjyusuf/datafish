package com.datafish.inventory.controller;

import com.datafish.inventory.model.InventoryItem;
import com.datafish.inventory.model.InventoryTransaction;
import com.datafish.inventory.service.InventoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@CrossOrigin(origins = "*")
public class InventoryController {

    @Autowired
    private InventoryService inventoryService;

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "healthy");
        response.put("service", "inventory-service");
        response.put("time", Instant.now().getEpochSecond());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/api/inventory")
    public ResponseEntity<List<InventoryItem>> getAllInventory() {
        return ResponseEntity.ok(inventoryService.getAllItems());
    }

    @GetMapping("/api/inventory/{productId}")
    public ResponseEntity<InventoryItem> getInventoryByProductId(@PathVariable Long productId) {
        return inventoryService.getByProductId(productId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/api/inventory/low-stock")
    public ResponseEntity<List<InventoryItem>> getLowStockItems() {
        return ResponseEntity.ok(inventoryService.getLowStockItems());
    }

    @PostMapping("/api/inventory")
    public ResponseEntity<InventoryItem> createOrUpdateInventory(@RequestBody InventoryItem item) {
        return ResponseEntity.ok(inventoryService.createOrUpdate(item));
    }

    @PostMapping("/api/inventory/{productId}/receive")
    public ResponseEntity<?> receiveStock(
            @PathVariable Long productId,
            @RequestParam int quantity,
            @RequestParam(required = false) String notes) {
        try {
            InventoryItem item = inventoryService.receiveStock(productId, quantity, notes);
            return ResponseEntity.ok(item);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/api/inventory/{productId}/reserve")
    public ResponseEntity<?> reserveStock(
            @PathVariable Long productId,
            @RequestParam int quantity,
            @RequestParam String orderId) {
        try {
            InventoryItem item = inventoryService.reserveStock(productId, quantity, orderId);
            return ResponseEntity.ok(item);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/api/inventory/{productId}/release")
    public ResponseEntity<?> releaseReservation(
            @PathVariable Long productId,
            @RequestParam int quantity,
            @RequestParam String orderId) {
        try {
            InventoryItem item = inventoryService.releaseReservation(productId, quantity, orderId);
            return ResponseEntity.ok(item);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/api/inventory/{productId}/confirm-sale")
    public ResponseEntity<?> confirmSale(
            @PathVariable Long productId,
            @RequestParam int quantity,
            @RequestParam String orderId) {
        try {
            InventoryItem item = inventoryService.confirmSale(productId, quantity, orderId);
            return ResponseEntity.ok(item);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/api/inventory/{productId}/adjust")
    public ResponseEntity<?> adjustStock(
            @PathVariable Long productId,
            @RequestParam int newQuantity,
            @RequestParam String reason) {
        try {
            InventoryItem item = inventoryService.adjustStock(productId, newQuantity, reason);
            return ResponseEntity.ok(item);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/api/inventory/{productId}/transactions")
    public ResponseEntity<List<InventoryTransaction>> getTransactionHistory(@PathVariable Long productId) {
        return ResponseEntity.ok(inventoryService.getTransactionHistory(productId));
    }

    @GetMapping("/api/inventory/transactions/recent")
    public ResponseEntity<List<InventoryTransaction>> getRecentTransactions(
            @RequestParam(defaultValue = "24") int hours) {
        return ResponseEntity.ok(inventoryService.getRecentTransactions(hours));
    }

    @GetMapping("/api/inventory/stats")
    public ResponseEntity<Map<String, Object>> getInventoryStats() {
        return ResponseEntity.ok(inventoryService.getInventoryStats());
    }

    @PostMapping("/api/inventory/batch/sync")
    public ResponseEntity<Map<String, String>> triggerBatchSync() {
        inventoryService.syncWithWarehouse();
        return ResponseEntity.ok(Map.of(
                "message", "Batch sync triggered",
                "status", "completed"
        ));
    }
}




