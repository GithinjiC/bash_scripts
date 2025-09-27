package main

import (
	"bufio"
	"fmt"
	// "os"
	"strconv"
	"strings"
	"time"
	// "golang.org/x/text/language"
	// "golang.org/x/text/cases"
)

type Task struct {
	ID        int
	Title     string
	Priority  string
	Completed bool
}

var tasks []Task
var focusSessions int

// func main() {
// 	scanner := bufio.NewScanner(os.Stdin)
// 	fmt.Println("Welcome to FocusTimer!")
// 	for {
// 		fmt.Println("\nChoose an option:")
// 		fmt.Println("1. Add Task")
// 		fmt.Println("2. List Tasks")
// 		fmt.Println("3. Mark Task as Completed")
// 		fmt.Println("4. Start Focus Timer")
// 		fmt.Println("5. View Daily Summary")
// 		fmt.Println("6. Exit")

// 		fmt.Println("Enter your choice: ")
// 		scanner.Scan()
// 		choice := scanner.Text()

// 		switch choice {
// 		case "1":
// 			addTask(scanner)
// 		case "2":
// 			listTasks()
// 		case "3":
// 			markTaskCompleted(scanner)
// 		case "4":
// 			startFocusTimer()
// 		case "5":
// 			viewSummary()
// 		case "6":
// 			fmt.Println("Goodbye! Stay productive")
// 			return
// 		default:
// 			fmt.Println("Invalid choice. Please try again.")
// 		}
// 	}
// }

func addTask(scanner *bufio.Scanner) {
	fmt.Print("Enter task title: ")
	scanner.Scan()
	title := scanner.Text()

	fmt.Print("Enter task priority (L,M,H): ")
	scanner.Scan()
	priority := scanner.Text()

	task := Task{
		ID:       len(tasks) + 1,
		Title:    title,
		Priority: strings.Title(priority),
		// Priority: cases.Title(language.English(priority)),
		Completed: false,
	}
	tasks = append(tasks, task)
	fmt.Println("Task added successfully")
}

func listTasks() {
	if len(tasks) == 0 {
		fmt.Println("No tasks available")
		return
	}

	fmt.Println("\nTasks:")
	for _, task := range tasks {
		status := "Pending"
		if task.Completed {
			status = "Completed"
		}
		fmt.Printf("[%d] %s (Priority: %s) - %s\n", task.ID, task.Title, task.Priority, status)
	}
}

func markTaskCompleted(scanner *bufio.Scanner) {
	listTasks()
	fmt.Println("Enter the ID of the task to mark as completed: ")
	scanner.Scan()
	id, err := strconv.Atoi(scanner.Text())
	if err != nil || id <= 0 || id > len(tasks) {
		fmt.Println("Invalid task ID. Please try again.")
		return
	}

	tasks[id-1].Completed = true
	fmt.Println("Task marked as completed!")
}

func startFocusTimer() {
	fmt.Println("\nStarting focus timer for 25 minutes. Stay focused!")
	time.Sleep(25 * time.Minute)
	fmt.Println("Focus session completed! Take a 5-min break.")

	focusSessions++
	if focusSessions%4 == 0 {
		fmt.Println("You've completed 4 sessions! Take a 15-min break")
		time.Sleep(15 * time.Minute)
	} else {
		time.Sleep(5 * time.Minute)
	}
}

func viewSummary() {
	fmt.Println("\nDaily Summary: ")
	fmt.Printf("Total Focus Sessions: %d\n", focusSessions)
	fmt.Println("Completed Tasks:")
	for _, task := range tasks {
		if task.Completed {
			fmt.Printf("- %s (Priority: %s)\n", task.Title, task.Priority)
		}
	}
}
