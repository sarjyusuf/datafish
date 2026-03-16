package com.datafish.product.config;

import com.datafish.product.model.Product;
import com.datafish.product.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;

@Component
public class DataInitializer implements CommandLineRunner {
    
    @Autowired
    private ProductRepository productRepository;
    
    @Override
    public void run(String... args) {
        if (productRepository.count() == 0) {
            List<Product> products = Arrays.asList(
                // APM & Tracing Fish
                new Product(null, "Trace Span Clownfish", "Swims through your distributed systems leaving colorful trace spans everywhere! 99.9% uptime guaranteed or your money back.", 
                    new BigDecimal("29.99"), "APM", 500, "/images/Trace_Span_Clownfish.png", "small", "saltwater", true, null, null),
                new Product(null, "Blue APM Tang", "This fish monitors everything - literally EVERYTHING. Side effects include alert fatigue and dashboard addiction.", 
                    new BigDecimal("49.99"), "APM", 350, "/images/Blue_APM_Tang.png", "medium", "saltwater", true, null, null),
                new Product(null, "Distributed Tracing Discus", "King of the aquarium! Traces requests across all microservices. Comes with built-in flame graphs on its fins.", 
                    new BigDecimal("89.99"), "APM", 200, "/images/Distributed_Tracing_Discus.png", "medium", "freshwater", true, null, null),
                new Product(null, "Neon Trace-tra", "Tiny but mighty! Schools of these fish create beautiful service maps. Buy in bulk for full observability coverage!", 
                    new BigDecimal("3.99"), "APM", 9999, "/images/Neon_Trace-tra.png", "small", "freshwater", false, null, null),
                
                // Metrics & Monitoring Fish
                new Product(null, "Betta Metrics Fish", "Always fighting to give you BETTER metrics! Aggressive about SLIs. Cannot be kept with other monitoring solutions.", 
                    new BigDecimal("15.99"), "Metrics", 800, "/images/Betta_Metrics_Fish.png", "small", "freshwater", true, null, null),
                new Product(null, "Golden Signal Fish", "Monitors the 4 golden signals: Latency, Traffic, Errors, and Saturation. Also looks great in photos!", 
                    new BigDecimal("5.99"), "Metrics", 1500, "/images/Golden_Signal_Fish.png", "small", "freshwater", false, null, null),
                new Product(null, "Gauge Guppy", "Breeds faster than your metric cardinality! Perfect for time-series databases. Warning: May explode your storage costs.", 
                    new BigDecimal("4.99"), "Metrics", 2000, "/images/Gauge_Guppy.png", "small", "freshwater", false, null, null),
                new Product(null, "Counter Platy", "Counts everything that moves. Increments only, never decrements. Perfect for tracking total requests!", 
                    new BigDecimal("6.99"), "Metrics", 1200, "/images/Counter_Platy.png", "small", "freshwater", false, null, null),
                
                // Logs & Events Fish
                new Product(null, "Log Angel", "Aggregates all your logs into beautiful structured JSON. Wings are actually indexed fields!", 
                    new BigDecimal("24.99"), "Logs", 600, "/images/Log_Angel.png", "medium", "freshwater", false, null, null),
                new Product(null, "Event Stream Fancy", "Premium fish that streams events in real-time! Supports webhooks, Kafka, and carrier pigeons.", 
                    new BigDecimal("19.99"), "Logs", 450, "/images/Event_Stream_Fancy.png", "medium", "freshwater", false, null, null),
                
                // SLO & Performance Fish
                new Product(null, "KPI Fish", "Not just beautiful - it's a Key Performance Indicator! Measures success by the number of compliments it receives.", 
                    new BigDecimal("99.99"), "SLO", 250, "/images/KPI_Fish.png", "large", "freshwater", true, null, null),
                new Product(null, "SLO Butterfly", "Elegant fish that helps you meet your Service Level Objectives. Fails gracefully when SLOs are breached.", 
                    new BigDecimal("129.99"), "SLO", 180, "/images/SLO_Butterfly.png", "large", "freshwater", false, null, null),
                new Product(null, "Platency Fish", "Obsessed with low latency! p50, p95, p99 - this fish tracks them all. Measures everything in microseconds.", 
                    new BigDecimal("6.99"), "SLO", 1000, "/images/Platency_Fish.png", "small", "freshwater", false, null, null),
                
                // Alerting & Incidents Fish
                new Product(null, "Alert Lionfish", "ALERT! ALERT! This fish is ALWAYS alerting! Stunning but dangerous. May cause PagerDuty fatigue.", 
                    new BigDecimal("149.99"), "Alerting", 100, "/images/Alert_Lionfish.png", "medium", "saltwater", true, null, null),
                new Product(null, "Error-wana", "Dragon fish that brings good luck... by catching all your errors before customers do! Exotic exception handler.", 
                    new BigDecimal("299.99"), "Alerting", 75, "/images/Error-wana.png", "large", "freshwater", false, null, null),
                new Product(null, "Incident Response Puffer", "Inflates when things go wrong! The bigger it gets, the worse your outage. Deflates after postmortem.", 
                    new BigDecimal("69.99"), "Alerting", 300, "/images/Incident_Response_Puffer.png", "small", "saltwater", false, null, null),
                
                // Profiling & Optimization Fish
                new Product(null, "Flame Graph Profiler", "This fish IS a flame graph! Shows you exactly where your CPU cycles go. Warning: May reveal embarrassing code.", 
                    new BigDecimal("89.99"), "Profiling", 220, "/images/Flame_Graph_Profiler.png", "medium", "freshwater", true, null, null),
                new Product(null, "Continuous Profiler", "Never stops profiling. Not even when sleeping. Especially not when sleeping. That's when the bugs come out!", 
                    new BigDecimal("79.99"), "Profiling", 280, "/images/Continuous_Profiler.png", "medium", "freshwater", false, null, null)
            );
            
            productRepository.saveAll(products);
            System.out.println("✓ Initialized " + products.size() + " products");
        }
    }
}
