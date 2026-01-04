package main

import (
	"flag"
	"io"
	"log"
	"os"
	"os/exec"
	"strconv"

	"github.com/gdamore/tcell/v2"
	"github.com/peltho/tufw/internal/core/service"
)

const (
	Green tcell.Color = tcell.ColorGreen
	Red   tcell.Color = tcell.ColorRed
	Blue  tcell.Color = tcell.ColorBlue
	Cyan  tcell.Color = tcell.ColorDarkCyan
)

func main() {
	cmd := exec.Command("id", "-u")
	output, _ := cmd.Output()
	i, _ := strconv.Atoi(string(output[:len(output)-1]))
	if i != 0 {
		log.Fatal("本程序必须以 root 权限运行！(sudo)")
	}

	cmd = exec.Command("ufw", "status")
	_, err := cmd.Output()
	if err != nil {
		log.Fatal("找不到 ufw。请检查是否已安装。")
	}

	colorFlag := flag.String("color", "cyan", "Color value (red, green, blue)")
	logFlag := flag.String("log", "", "Log everything into a tufw.log file")
	flag.Parse()

	var color tcell.Color
	switch *colorFlag {
	case "red":
		color = Red
	case "green":
		color = Green
	case "blue":
		color = Blue
	case "cyan":
		color = Cyan
	default:
		log.Fatalf("无效颜色：%s。允许的值为 red, green, blue。", *colorFlag)
	}

	if *logFlag != "" {
		f, err := os.OpenFile(*logFlag, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			log.Fatal(err)
		}
		log.SetOutput(f)
		defer f.Close()
	} else {
		log.SetOutput(io.Discard)
	}

	tui := service.CreateApplication(color)
	tui.Init()
	data, err := tui.LoadUFWOutput()
	if err != nil {
		log.Print(err)
	}
	tui.Build(data)
}
