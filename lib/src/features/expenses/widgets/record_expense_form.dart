part of '../record_expense_screen.dart';

extension _RecordExpenseFormView on _RecordExpenseScreenState {
  Widget buildContent(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    if (household == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _spentBy ??= user.uid;
    final categories =
        household.categories.where((c) => !c.archived).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    // Smart default: most-used category this cycle (falls back to the first
    // chip). Keeps re-evaluating until the user taps a chip or a keyword
    // suggestion kicks in, so it still applies once the stream loads.
    if (!_categoryTouched && _suggestedCategoryId == null &&
        categories.isNotEmpty) {
      final cycleExpenses =
          ref.watch(cycleExpensesProvider).value ?? const <Expense>[];
      _categoryId =
          _mostUsedCategoryId(cycleExpenses, categories) ?? categories.first.id;
    } else if (_categoryId == null && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }
    final cards = ref.watch(cardsProvider(household.id)).value ?? const [];
    // Drop a remembered card that no longer exists, then default.
    if (!widget.isEdit &&
        cards.isNotEmpty &&
        _cardId != null &&
        cards.every((c) => c.id != _cardId)) {
      _cardId = null;
    }
    if (_prefsLoaded &&
        _payType == 'credit' &&
        _cardId == null &&
        cards.isNotEmpty) {
      _cardId = cards.first.id;
      _cicilanApr = cards.first.apr;
    }
    // Remembered card applied from prefs skips the default branch above —
    // sync its APR for the cicilan preview.
    if (_payType == 'credit' && _cardId != null && !_cicilan &&
        _cicilanApr == 0.0) {
      for (final c in cards) {
        if (c.id == _cardId) {
          _cicilanApr = c.apr;
          break;
        }
      }
    }
    final cicilanLock = widget.isCicilan;
    final sourceAccounts = recordAccountChoices(
      cashAccounts: household.cashAccounts,
      savingsAccounts: household.savingsAccounts,
    );
    // Drop a remembered account that no longer exists, then default.
    if (!widget.isEdit &&
        _sourceAccountId != null &&
        sourceAccounts.every((a) => a.id != _sourceAccountId)) {
      _sourceAccountId = null;
    }
    if (_prefsLoaded &&
        _payType == 'cash' &&
        _sourceAccountId == null &&
        sourceAccounts.isNotEmpty) {
      _sourceAccountId = sourceAccounts.first.id;
    }
    final canSubmit = _amount > 0 &&
        _categoryId != null &&
        ref.watch(canRecordTxnProvider) &&
        (_payType == 'credit' ||
            sourceAccounts.isEmpty ||
            _sourceAccountId != null);

    return Scaffold(
      backgroundColor: FtColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: FtPageContainer(
        child: Column(
          children: [
            FtSubHeader(
              title: widget.isEdit ? 'Edit pengeluaran' : 'Catat pengeluaran',
              trailing: FtSubmitDot(
                busy: _busy,
                enabled: canSubmit,
                onTap: () => _submit(household, cards),
              ),
            ),
            Expanded(
              child: FtFadeUp(
                duration: const Duration(milliseconds: 320),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  children: [
                    if (cicilanLock) ...[
                      const CicilanLockedBanner(),
                      const SizedBox(height: 16),
                    ],
                    if (!widget.isEdit)
                      ExpenseFavoritesRow(
                        categories: categories,
                        onPick: _applyFavorite,
                      ),
                    AbsorbPointer(
                      absorbing: cicilanLock,
                      child: Opacity(
                        opacity: cicilanLock ? 0.5 : 1,
                        child: MoneyField(
                          amount: _amount,
                          calculator: true,
                          onChanged: (v) => _rebuild(() => _amount = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Eyebrow('Kategori'),
                        if (_suggestedCategoryId != null &&
                            _suggestedCategoryId == _categoryId) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.auto_awesome,
                              size: 11, color: FtColors.clay),
                          const SizedBox(width: 3),
                          Text(
                            'disarankan dari catatan',
                            style: TextStyle(
                              fontSize: 10,
                              color: FtColors.ink3,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    CategoryChipRow(
                      categories: categories,
                      selected: _categoryId,
                      onSelect: (id) {
                        FtHaptics.select();
                        _rebuild(() {
                          _categoryId = id;
                          _categoryTouched = true;
                          _suggestedCategoryId = null;
                        });
                      },
                    ),
                    // Split: belanja campur (struk supermarket dll) dibagi ke
                    // beberapa kategori sekaligus.
                    if (!widget.isEdit && !_cicilan && _amount > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed:
                              _busy ? null : () => _openSplit(household),
                          icon: const Icon(Icons.call_split_rounded,
                              size: 15),
                          label: const Text(
                            'Split ke beberapa kategori',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 22),
                    const Eyebrow('Pembayaran'),
                    const SizedBox(height: 10),
                    AbsorbPointer(
                      absorbing: cicilanLock,
                      child: Opacity(
                        opacity: cicilanLock ? 0.5 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PayTypeToggle(
                              value: _payType,
                              onChange: (v) {
                                FtHaptics.select();
                                _rebuild(() => _payType = v);
                              },
                            ),
                            const SizedBox(height: 14),
                            if (_payType == 'cash')
                              RecordAccountDropdownField(
                                accounts: sourceAccounts,
                                selectedId: _sourceAccountId,
                                accent: FtColors.ink,
                                sheetTitle: 'Pilih rekening',
                                onSelect: (id) {
                                  FtHaptics.select();
                                  _rebuild(() => _sourceAccountId = id);
                                },
                                emptyNote:
                                    'Belum ada rekening. Pengeluaran tetap tercatat tapi saldo tidak terpotong. Tambah dari Aset → Tunai.',
                              )
                            else
                              CardPicker(
                                cards: cards,
                                selected: _cardId,
                                onSelect: (id) {
                                  FtHaptics.select();
                                  _rebuild(() {
                                    _cardId = id;
                                    final c = cards
                                        .firstWhere((x) => x.id == id);
                                    _cicilanApr = c.apr;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Cicilan picker only shown when creating a new credit
                    // expense — in edit mode the plan is immutable.
                    if (!widget.isEdit &&
                        _payType == 'credit' &&
                        cards.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Eyebrow('Cicilan'),
                      const SizedBox(height: 10),
                      InstallmentPlans(
                        cicilan: _cicilan,
                        months: _cicilanMonths,
                        apr: _cicilanApr,
                        onSelect: (months, apr) {
                          FtHaptics.select();
                          _rebuild(() {
                            _cicilan = months > 1;
                            _cicilanMonths = months > 1 ? months : 6;
                            _cicilanApr = apr;
                          });
                        },
                      ),
                      if (_cicilan && _amount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: InstallmentPreview(
                            amount: _amount,
                            months: _cicilanMonths,
                            apr: _cicilanApr,
                          ),
                        ),
                    ],
                    const SizedBox(height: 22),
                    FtInput(
                      label: 'Catatan (opsional)',
                      controller: _note,
                      hintText: 'Misal: Kopi Tuku',
                    ),
                    const SizedBox(height: 14),
                    RecordMetaRow(
                      date: _date,
                      recurring: _recurring,
                      onPickDate: _pickDate,
                      onToggleRecurring: _cicilan
                          ? null
                          : (v) {
                              FtHaptics.select();
                              _rebuild(() => _recurring = v);
                            },
                    ),
                    if (!widget.isEdit) ...[
                      const SizedBox(height: 10),
                      QuickDateChips(
                        selected: _date,
                        onPick: (d) {
                          FtHaptics.select();
                          _rebuild(() => _date = d);
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kategori, tanggal, dan detail bisa diubah kapan saja.',
                        style: TextStyle(
                          color: FtColors.ink4,
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                      ),
                    ],
                    if (!widget.isEdit) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (canSubmit && !_busy)
                                  ? () => _submit(household, cards,
                                      addAnother: true)
                                  : null,
                              icon: const Icon(Icons.playlist_add_rounded,
                                  size: 18),
                              label: const Text('Simpan & tambah lagi'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: (_amount > 0 && _categoryId != null)
                                ? _saveFavorite
                                : null,
                            tooltip: 'Jadikan favorit',
                            icon: Icon(
                              Icons.star_border_rounded,
                              color: FtColors.clay,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
