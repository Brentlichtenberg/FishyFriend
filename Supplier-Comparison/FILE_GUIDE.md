# 📖 Documentation Guide - What to Read When

## 🚀 I Want to Get Started FAST
**Read:** `QUICKSTART.md`
- 5-minute setup guide
- Essential steps only
- Get running quickly

---

## ✅ I'm Following Step-by-Step
**Read:** `CHECKLIST.md`
- Complete checklist with boxes to check
- Detailed verification steps
- Troubleshooting included
- Perfect for first-time setup

---

## 🔄 I Need to Convert My Numbers File
**Read:** `CONVERT_NUMBERS.md`
- Step-by-step Numbers → CSV conversion
- Screenshots of what to click
- Format verification
- Troubleshooting export issues

---

## 📚 I Want Complete Documentation
**Read:** `README.md`
- Full technical documentation
- All features explained
- Advanced usage
- Architecture details
- Comprehensive troubleshooting

---

## 🎯 I Want a Project Overview
**Read:** `PROJECT_SUMMARY.md`
- What was created and why
- File structure explained
- Feature overview
- Usage examples
- Performance expectations

---

## 🔧 I'm Having Problems

### Setup Issues
1. Check `CHECKLIST.md` - Step-by-step troubleshooting
2. Run `python3 test_setup.py` - Automated checks
3. Check `price_scraper.log` - Detailed errors

### Runtime Issues
1. Check `price_scraper.log` - See what went wrong
2. Read `README.md` → Troubleshooting section
3. Verify spreadsheet format in `CONVERT_NUMBERS.md`

### Product Not Found Issues
1. Simplify product names
2. Check `README.md` → Product Matching section
3. Test with single product using `--product` flag

---

## 📁 File Reference

### Documentation Files
| File | Purpose | Read When |
|------|---------|-----------|
| `QUICKSTART.md` | Fast start | Want to start immediately |
| `CHECKLIST.md` | Step-by-step guide | First time setup |
| `CONVERT_NUMBERS.md` | Numbers conversion | Need to convert spreadsheet |
| `README.md` | Complete docs | Need full information |
| `PROJECT_SUMMARY.md` | Overview | Want to understand project |
| `FILE_GUIDE.md` | This file | Need navigation help |

### Code Files
| File | Purpose |
|------|---------|
| `price_scraper.py` | Main program - run this |
| `test_setup.py` | Verify installation |
| `setup.sh` | Install dependencies |
| `requirements.txt` | Python packages needed |

### Data Files
| File | Purpose |
|------|---------|
| `products_template.csv` | Example spreadsheet |
| `products.csv` | Your converted spreadsheet (you create this) |
| `ASTPSO Master Product List.numbers` | Your original file |

### Generated Files (after running)
| File | Purpose |
|------|---------|
| `price_scraper.log` | Detailed operation logs |
| `products.csv.backup` | Backup before updates |
| `__pycache__/` | Python cache (ignore) |

---

## 🎯 Common Scenarios

### Scenario 1: Brand New User
**Path:**
1. `CHECKLIST.md` - Follow all steps
2. `CONVERT_NUMBERS.md` - Convert your file
3. Run: `./setup.sh`
4. Run: `python3 test_setup.py`
5. Run: `python3 price_scraper.py products.csv`

---

### Scenario 2: Quick Start User
**Path:**
1. `QUICKSTART.md` - Speed run setup
2. Convert Numbers file
3. Run: `./setup.sh && python3 price_scraper.py products.csv`

---

### Scenario 3: Technical User
**Path:**
1. `README.md` - Full technical docs
2. `PROJECT_SUMMARY.md` - Architecture
3. Customize as needed

---

### Scenario 4: Having Problems
**Path:**
1. Check `price_scraper.log` file
2. Read `CHECKLIST.md` → Troubleshooting section
3. Read `README.md` → Troubleshooting section
4. Run `python3 test_setup.py`

---

## 💡 Pro Tips

### First Time Running
- Start with `CHECKLIST.md`
- Don't skip steps
- Test with 1 product first
- Check logs after each run

### Regular Use
- Keep `QUICKSTART.md` bookmarked
- Monitor `price_scraper.log`
- Compare backups for price changes

### Troubleshooting
- Always check logs first
- Use `test_setup.py` to verify installation
- Test single products to isolate issues

---

## 📞 Quick Help

**Can't get started?**
→ `CHECKLIST.md`

**Scraper not working?**
→ Check `price_scraper.log`

**Products not found?**
→ `README.md` → Product Matching section

**Numbers conversion?**
→ `CONVERT_NUMBERS.md`

**Want to understand everything?**
→ `README.md` + `PROJECT_SUMMARY.md`

---

## 🎓 Learning Path

### Level 1: Beginner
1. `QUICKSTART.md` or `CHECKLIST.md`
2. Basic usage
3. Understand output

### Level 2: Regular User
1. `README.md` - Features section
2. Understand logs
3. Customize product names

### Level 3: Advanced
1. `README.md` - Complete
2. `PROJECT_SUMMARY.md`
3. Code files (understand architecture)
4. Modify scrapers if needed

---

## ✅ Summary

**Start here:**
- New? → `CHECKLIST.md`
- Fast? → `QUICKSTART.md`
- Convert? → `CONVERT_NUMBERS.md`

**Go deeper:**
- Everything → `README.md`
- Overview → `PROJECT_SUMMARY.md`

**Get help:**
- Logs → `price_scraper.log`
- Test → `python3 test_setup.py`

---

**Happy scraping!** 🎉
