package com.datafish.inventory;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class InventoryServiceApplication {

    public static void main(String[] args) {
        System.out.println("📦 Inventory Service starting...");
        SpringApplication.run(InventoryServiceApplication.class, args);
    }
}




