package main

import (
	"database/sql"
	"encoding/csv"
	"fmt"
	"log"
	"math/rand"
	"os"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

func generateLogFileName(extension string) string {
	timestamp := time.Now().Format("20060102_150405")
	return fmt.Sprintf("output_%s.%s", timestamp, extension)
}

func setupLogging(logFileName string) {
	logFile, err := os.OpenFile(logFileName, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		fmt.Printf("Error opening log file: %v\n", err)
		os.Exit(1)
	}
	log.SetOutput(logFile)
}

func generateHumanNames(count int) []string {
	firstNames := []string{"John", "Jane", "Carlos", "Aisha", "Li", "Anna"}
	lastNames := []string{"Doe", "Smith", "Lopez", "Khan", "Wei", "Ivannova"}
	names := []string{}
	for i := 0; i < count; i++ {
		firstName := firstNames[rand.Intn(len(firstNames))]
		lastName := lastNames[rand.Intn(len(lastNames))]
		names = append(names, fmt.Sprintf("%s %s", firstName, lastName))
	}

	return names
}

func nameToEmail(name string) string {
	email := strings.ReplaceAll(strings.ToLower(name), " ", ".")
	return email
}

func generatePhoneNumber() string {
	phoneNumber := "+2547"
	for i := 0; i < 8; i++ {
		phoneNumber += fmt.Sprintf("%d", rand.Intn(10))
	}
	return phoneNumber
}

func loadToPostgres(fileName string) {
	db, err := sql.Open("postgres", "user=lilith password=Vallakavaddi dbname=tests sslmode=disable")
	if err != nil {
		log.Fatalf("Error connecting to database: %v\n", err)
	}
	defer db.Close()

	file, err := os.Open(fileName)
	if err != nil {
		log.Fatalf("Error opening CSV file: %v\n", err)
	}
	defer file.Close()

	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil {
		log.Fatalf("Error reading CSV file: %v\n", err)
	}

	hasErrors := false
	for _, record := range records[1:] {
		_, err := db.Exec(`
			INSERT INTO users (id, name, email, age, country, phone_number, registration_date) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
			record[0], record[1], record[2], record[3], record[4], record[5], record[6])
		if err != nil {
			hasErrors = true
			log.Printf("Failed to insert record %v: %v\n", record, err)
		}
	}

	if !hasErrors {
		log.Println("Data successfully inserted to the database!")
	}
}

func generateCSV(fileName string) {
	file, err := os.Create(fileName)
	if err != nil {
		log.Printf("Error creating file: %v\n", err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	header := []string{"ID", "Name", "Email", "Age", "Country", "Phone No.", "Reg Date"}
	err = writer.Write(header)
	if err != nil {
		log.Printf("Error writing header: %v\n", err)
		return
	}

	names := generateHumanNames(100)
	countries := []string{"USA", "UK", "Mexico", "India", "China", "Russia", "Germany"}

	data := [][]string{}
	for i, name := range names {
		data = append(data, []string{
			fmt.Sprintf("%d", i+1),
			name,
			fmt.Sprintf("%s@example.com", nameToEmail(name)),
			fmt.Sprintf("%d", rand.Intn(50)+18), // random age 18-67
			countries[rand.Intn(len(countries))],
			generatePhoneNumber(),
			time.Now().AddDate(0, 0, -rand.Intn(365)).Format("2006-01-02"),
		})
	}

	for _, row := range data {
		err = writer.Write(row)
		if err != nil {
			log.Printf("Errror writing row: %v\n", err)
			return
		}
	}

	log.Printf("CSV file '%s' created with %d rows.\n", fileName, len(data)+1)
}

func main() {
	logFileName := generateLogFileName("log")
	setupLogging(logFileName)

	fileName := "generated.csv"

	generateCSV(fileName)

	loadToPostgres(fileName)
}
