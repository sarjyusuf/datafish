package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// Notification types
type OrderNotification struct {
	OrderID         int     `json:"orderId" binding:"required"`
	CustomerEmail   string  `json:"customerEmail" binding:"required"`
	TotalAmount     float64 `json:"totalAmount" binding:"required"`
	ItemCount       int     `json:"itemCount"`
	ShippingAddress string  `json:"shippingAddress"`
}

type LowStockNotification struct {
	ProductID   int    `json:"productId" binding:"required"`
	ProductName string `json:"productName" binding:"required"`
	StockLevel  int    `json:"stockLevel" binding:"required"`
}

type EmailRequest struct {
	To      string `json:"to" binding:"required,email"`
	Subject string `json:"subject" binding:"required"`
	Body    string `json:"body" binding:"required"`
}

// In-memory notification log
type NotificationLog struct {
	ID        int       `json:"id"`
	Type      string    `json:"type"`
	Recipient string    `json:"recipient"`
	Subject   string    `json:"subject"`
	Body      string    `json:"body"`
	Status    string    `json:"status"`
	SentAt    time.Time `json:"sentAt"`
}

var notificationLogs = []NotificationLog{}
var nextID = 1

func main() {
	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()

	// CORS
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Routes
	r.GET("/health", healthCheck)
	r.POST("/api/notifications/order", sendOrderNotification)
	r.POST("/api/notifications/low-stock", sendLowStockNotification)
	r.POST("/api/notifications/email", sendEmail)
	r.GET("/api/notifications/logs", getNotificationLogs)

	port := getEnv("PORT", "8083")
	log.Printf("🐟 Notification Service starting on port %s", port)
	r.Run(":" + port)
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "notification-service",
		"time":    time.Now().Unix(),
	})
}

func sendOrderNotification(c *gin.Context) {
	var notification OrderNotification
	if err := c.ShouldBindJSON(&notification); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Simulate sending order confirmation email
	subject := "🐟 DataFish - Order Confirmation"
	body := formatOrderEmail(notification)
	
	logNotification("order_confirmation", notification.CustomerEmail, subject, body, "sent")
	
	// Simulate async email sending
	go func() {
		log.Printf("📧 Sending order confirmation to %s for order #%d", 
			notification.CustomerEmail, notification.OrderID)
		time.Sleep(100 * time.Millisecond) // Simulate email sending
	}()

	c.JSON(http.StatusOK, gin.H{
		"message": "Order notification sent successfully",
		"orderId": notification.OrderID,
		"sentTo":  notification.CustomerEmail,
	})
}

func sendLowStockNotification(c *gin.Context) {
	var notification LowStockNotification
	if err := c.ShouldBindJSON(&notification); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Send low stock alert to admin
	adminEmail := "admin@datafish.com"
	subject := "⚠️ Low Stock Alert"
	body := formatLowStockEmail(notification)
	
	logNotification("low_stock_alert", adminEmail, subject, body, "sent")
	
	go func() {
		log.Printf("⚠️ Low stock alert for %s (Stock: %d)", 
			notification.ProductName, notification.StockLevel)
	}()

	c.JSON(http.StatusOK, gin.H{
		"message":     "Low stock notification sent",
		"productId":   notification.ProductID,
		"productName": notification.ProductName,
		"stockLevel":  notification.StockLevel,
	})
}

func sendEmail(c *gin.Context) {
	var email EmailRequest
	if err := c.ShouldBindJSON(&email); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	logNotification("custom_email", email.To, email.Subject, email.Body, "sent")
	
	go func() {
		log.Printf("📧 Sending email to %s: %s", email.To, email.Subject)
		time.Sleep(100 * time.Millisecond)
	}()

	c.JSON(http.StatusOK, gin.H{
		"message": "Email sent successfully",
		"to":      email.To,
	})
}

func getNotificationLogs(c *gin.Context) {
	c.JSON(http.StatusOK, notificationLogs)
}

func formatOrderEmail(notification OrderNotification) string {
	return `
Thank you for your order at DataFish!

Order Details:
--------------
Order ID: #` + string(rune(notification.OrderID)) + `
Total Amount: $` + string(rune(int(notification.TotalAmount))) + `
Items: ` + string(rune(notification.ItemCount)) + `

Shipping Address:
` + notification.ShippingAddress + `

Your fish will be carefully packaged and shipped within 24 hours.

Thank you for shopping with DataFish!
🐟 The DataFish Team
	`
}

func formatLowStockEmail(notification LowStockNotification) string {
	return `
Low Stock Alert!

Product: ` + notification.ProductName + `
Product ID: ` + string(rune(notification.ProductID)) + `
Current Stock: ` + string(rune(notification.StockLevel)) + `

Please reorder this product soon.

- DataFish Inventory System
	`
}

func logNotification(notifType, recipient, subject, body, status string) {
	log := NotificationLog{
		ID:        nextID,
		Type:      notifType,
		Recipient: recipient,
		Subject:   subject,
		Body:      body,
		Status:    status,
		SentAt:    time.Now(),
	}
	nextID++
	notificationLogs = append(notificationLogs, log)
	
	// Keep only last 100 notifications
	if len(notificationLogs) > 100 {
		notificationLogs = notificationLogs[1:]
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

