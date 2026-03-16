package com.datafish.inventory.repository;

import com.datafish.inventory.model.InventoryTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TransactionRepository extends JpaRepository<InventoryTransaction, Long> {

    List<InventoryTransaction> findByProductIdOrderByCreatedAtDesc(Long productId);

    List<InventoryTransaction> findByTypeOrderByCreatedAtDesc(InventoryTransaction.TransactionType type);

    @Query("SELECT t FROM InventoryTransaction t WHERE t.createdAt >= ?1 ORDER BY t.createdAt DESC")
    List<InventoryTransaction> findRecentTransactions(LocalDateTime since);

    @Query("SELECT t FROM InventoryTransaction t WHERE t.productId = ?1 AND t.createdAt >= ?2")
    List<InventoryTransaction> findByProductIdAndCreatedAtAfter(Long productId, LocalDateTime since);

    @Query("SELECT COUNT(t) FROM InventoryTransaction t WHERE t.type = ?1")
    Long countByType(InventoryTransaction.TransactionType type);
}




